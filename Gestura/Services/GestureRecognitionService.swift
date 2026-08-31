//
//  GestureRecognitionService.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 24/05/2026.
//

import AVFoundation
import CoreML
import Foundation
import ImageIO
import QuartzCore
import Vision

final class GestureRecognitionService: NSObject {
    // MARK: - TYPES

    /// The outcome of attempting to start the recognizer. Lets the caller
    /// surface a recovery UI instead of crashing or silently hanging.
    enum StartResult: Equatable {
        case started
        case cameraDenied
        case modelUnavailable
    }

    /// Live per-frame view of what the camera sees, for the framing / no-hand
    /// UI. Emitted only on change (not every frame).
    enum FrameStatus: Equatable {
        case noHand        // no hand found in the frame
        case handDetected  // a hand is in frame (gesture may or may not match)
    }

    // MARK: - PROPERTIES
    let detectionStream: AsyncStream<GestureDetection>
    private let detectionContinuation:
        AsyncStream<GestureDetection>.Continuation
    let statusStream: AsyncStream<FrameStatus>
    private let statusContinuation: AsyncStream<FrameStatus>.Continuation
    // Last status emitted; used to de-dupe. Touched only on processingQueue.
    private var lastStatus: FrameStatus?
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(
        label: "com.mohab.Gestura.GestureRecognitionService.sessionQueue"
    )
    private let processingQueue = DispatchQueue(
        label: "com.mohab.Gestura.GestureRecognitionService.processingQueue"
    )
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var isConfigured = false
    // Whether the recognizer is *meant* to be running. Tracked so we can
    // resume after a system interruption (e.g. a phone call) ends — but only
    // if stop() wasn't called meanwhile. Touched only on sessionQueue.
    private var shouldBeRunning = false

    // Software frame throttling. Processed only on processingQueue.
    private var lastProcessedTime: CFTimeInterval = 0
    private let frameProcessingInterval: CFTimeInterval = 1.0 / 12.0  // ~12 fps

    // The orientation that turns the raw front-camera buffer upright for
    // Vision. This is not cosmetic: the classifier consumes normalized
    // keypoint coordinates *in this frame*, so it has to match the orientation
    // of the footage the model was trained on.
    //
    // It was `.right` — the back-camera portrait convention — which rotated
    // every frame a quarter turn. The gestures defined by a direction
    // (point_left / point_right) came out looking like the gestures defined by
    // a thumb and were classified as thumbs_up / thumbs_down, while the
    // rotation-agnostic open_palm kept working. `.leftMirrored` was confirmed
    // on device with the orientation sweep at the bottom of this file: it is
    // the only candidate that names all five gestures correctly.
    //
    // This value is paired with the mirroring decision in
    // `configureSessionSync` — the two describe one transform between sensor
    // and model, so neither can be changed alone. Re-run the sweep if either
    // moves, or if the model is retrained on differently captured footage.
    private static let inferenceOrientation: CGImagePropertyOrientation =
        .leftMirrored

    #if DEBUG
    /// Logs what every candidate orientation makes of the current frame.
    /// Flip to `true` to re-run the sweep — after retraining the model, or if
    /// direction-dependent gestures start misfiring again.
    static var orientationDiagnosticEnabled = false
    // A sweep is eight Vision requests plus eight classifications, so it runs
    // far slower than the recognizer itself.
    private let sweepInterval: CFTimeInterval = 0.5
    private var lastSweepTime: CFTimeInterval = 0
    #endif

    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()

    private let handPoseClassifier: GesturaHandPoseClassifier? = {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        do {
            return try GesturaHandPoseClassifier(configuration: config)
        } catch {
            log("⚠️ Failed to load CoreML model: \(error)")
            return nil
        }
    }()

    // MARK: - INIT

    override init() {
        let (stream, continuation) = AsyncStream<GestureDetection>.makeStream()
        self.detectionStream = stream
        self.detectionContinuation = continuation
        let (statusStream, statusContinuation) =
            AsyncStream<FrameStatus>.makeStream()
        self.statusStream = statusStream
        self.statusContinuation = statusContinuation
        super.init()

        // System interruptions (incoming call, another app taking the camera,
        // Control Center) pause the session out from under us. We resume once
        // the interruption ends — see sessionInterruptionEnded.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted(_:)),
            name: AVCaptureSession.wasInterruptedNotification,
            object: captureSession
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded(_:)),
            name: AVCaptureSession.interruptionEndedNotification,
            object: captureSession
        )
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
        detectionContinuation.finish()
        statusContinuation.finish()
    }
    // MARK: - AUTHORIZATION

    static func requestCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - LIFECYCLE

    func start() async -> StartResult {
        
        guard handPoseClassifier != nil else { return .modelUnavailable }

        let authorized = await Self.requestCameraAuthorization()
        guard authorized else { return .cameraDenied }

        sessionQueue.async {
            [weak self] in
            guard let self else { return }
            self.shouldBeRunning = true
            if !self.isConfigured {
                self.configureSessionSync()
                self.isConfigured = true
            }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
        return .started
    }

    func stop() {
        sessionQueue.async {
            [weak self] in
            guard let self else { return }
            self.shouldBeRunning = false
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
        // Reset de-dupe state so the next run re-emits its first status.
        processingQueue.async { [weak self] in self?.lastStatus = nil }
    }

    // MARK: - INTERRUPTION HANDLING

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        // The system paused our session (phone call, another app grabbed the
        // camera, etc.). The camera stops automatically; we just wait for the
        // interruption to end.
        log("⚠️ Capture session interrupted")
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            // Only resume if we're still meant to be running (stop() may have
            // run during the interruption) and aren't already running.
            guard self.shouldBeRunning, !self.captureSession.isRunning else {
                return
            }
            self.captureSession.startRunning()
        }
    }

    // MARK: - SESSION CONFIGURATION

    private func configureSessionSync() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.automaticallyConfiguresApplicationAudioSession = false

        if captureSession.canSetSessionPreset(.vga640x480) {
            captureSession.sessionPreset = .vga640x480
        }

        guard
            let frontCamera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            )
        else {
            log(
                "⚠️ Front Camera unavilable"
            )
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            guard captureSession.canAddInput(input) else {
                log("⚠️ Cannot add camera input")
                return
            }
            captureSession.addInput(input)
        } catch {
            log("⚠️ Failed to create camera input: \(error)")
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: processingQueue)
        output.alwaysDiscardsLateVideoFrames = true
        guard captureSession.canAddOutput(output) else {
            log("⚠️ Cannot add video output")
            return
        }
        captureSession.addOutput(output)
        videoDataOutput = output

        // Mirroring is turned off here so the delegate receives the raw
        // sensor buffer, and the whole sensor-to-model transform is then
        // expressed in one place: `inferenceOrientation`, which Vision
        // applies. Splitting the transform across both would make each half
        // unreadable on its own.
        //
        // Note that `inferenceOrientation` is `.leftMirrored` — the flip the
        // model wants is real, it is just applied by Vision rather than by
        // the capture connection. Enabling mirroring here without changing
        // that constant would apply the flip twice.
        if let connection = output.connection(with: .video),
           connection.isVideoMirroringSupported
        {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
    }
}

// MARK: - SAMPLE BUFFER DELEGATE

extension GestureRecognitionService:
    AVCaptureVideoDataOutputSampleBufferDelegate
{
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        guard now - lastProcessedTime > frameProcessingInterval else { return }
        lastProcessedTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        #if DEBUG
        if Self.orientationDiagnosticEnabled {
            runOrientationSweep(on: pixelBuffer, at: now)
        }
        #endif

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: Self.inferenceOrientation,
            options: [:]
        )
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                emitStatus(.noHand)
                return
            }
            emitStatus(.handDetected)
            guard let poseKeypoints = try? observation.keypointsMultiArray()
            else { return }
            guard let handPoseClassifier else { return }
            let prediction = try handPoseClassifier.prediction(
                poses: poseKeypoints
            )
            guard let gesture = Gesture(rawValue: prediction.label) else {
                return
            }
            let confidence =
                prediction.labelProbabilities[prediction.label] ?? 0
            guard
                confidence
                    >= RecognizerSensitivity.current().settings
                    .confidenceThreshold
            else { return }
            detectionContinuation.yield(
                GestureDetection(gesture: gesture, confidence: confidence)
            )
        } catch {
            log("⚠️ Vision request failed: \(error)")
        }
    }

    /// Emit a status only when it differs from the last. Called on
    /// processingQueue (the sample-buffer delegate queue), so `lastStatus`
    /// is single-threaded.
    private func emitStatus(_ status: FrameStatus) {
        guard status != lastStatus else { return }
        lastStatus = status
        statusContinuation.yield(status)
    }

}

// MARK: - ORIENTATION SWEEP (DEBUG ONLY)

#if DEBUG
extension GestureRecognitionService {
    /// Every orientation the raw buffer could plausibly need. The mirrored
    /// variants are in here on purpose: a front-camera buffer can differ from
    /// the trained-on footage by a flip as well as a rotation, and
    /// `configureSessionSync` deliberately turns the connection's own
    /// mirroring off.
    fileprivate static let candidateOrientations:
        [(name: String, value: CGImagePropertyOrientation)] = [
            ("up", .up),
            ("down", .down),
            ("left", .left),
            ("right", .right),
            ("upMirrored", .upMirrored),
            ("downMirrored", .downMirrored),
            ("leftMirrored", .leftMirrored),
            ("rightMirrored", .rightMirrored),
        ]

    /// Classifies one frame under every candidate orientation and logs what
    /// each one makes of it.
    ///
    /// Hold a single gesture steady — `point_right` is the one to use, since
    /// it is the gesture a wrong orientation destroys — and read the console.
    /// The correct orientation is the row that names the gesture you are
    /// actually holding, with a confidence well clear of the others. Put that
    /// value in `inferenceOrientation` and set
    /// `orientationDiagnosticEnabled` back to `false`.
    func runOrientationSweep(
        on pixelBuffer: CVPixelBuffer,
        at now: CFTimeInterval
    ) {
        guard now - lastSweepTime > sweepInterval else { return }
        lastSweepTime = now
        guard let handPoseClassifier else { return }

        var rows: [String] = []
        for candidate in Self.candidateOrientations {
            let name = candidate.name.padding(
                toLength: 14,
                withPad: " ",
                startingAt: 0
            )
            // A fresh request per candidate: VNRequest holds its results, so
            // reusing the recognizer's would race with the live path.
            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: candidate.value,
                options: [:]
            )
            do {
                try handler.perform([request])
                guard
                    let observation = request.results?.first,
                    let keypoints = try? observation.keypointsMultiArray()
                else {
                    rows.append("  \(name) no hand found")
                    continue
                }
                let prediction = try handPoseClassifier.prediction(
                    poses: keypoints
                )
                rows.append(
                    "  \(name) \(Self.topLabels(prediction.labelProbabilities))"
                )
            } catch {
                rows.append("  \(name) failed: \(error.localizedDescription)")
            }
        }
        log("🧭 orientation sweep\n" + rows.joined(separator: "\n"))
    }

    /// The three likeliest labels, highest first, as `label 0.93` pairs.
    fileprivate static func topLabels(
        _ probabilities: [String: Double]
    ) -> String {
        probabilities
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "\($0.key) \(String(format: "%.2f", $0.value))" }
            .joined(separator: "   ")
    }
}
#endif
