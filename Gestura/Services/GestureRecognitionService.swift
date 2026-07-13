//
//  GestureRecognitionService.swift
//  Gestura
//
//  Created by Mohab Abdelatief on 24/05/2026.
//

import AVFoundation
import CoreML
import Foundation
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

    func requestCameraAuthorization() async -> Bool {
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
        // Bail before prompting for the camera if the model never loaded —
        // there's no point gating a feature that can't run.
        guard handPoseClassifier != nil else { return .modelUnavailable }

        let authorized = await requestCameraAuthorization()
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

        // The Hand Pose Classifier was trained on un-mirrored selfie
        // footage (iPhone Camera app default: Settings → Camera →
        // "Mirror Front Camera" = OFF). By default, AVCaptureConnection
        // auto-mirrors the front-camera buffer for selfie-style preview,
        // which would horizontally flip the image and cause point_left /
        // point_right to be detected as their opposite — plus cratered
        // confidence on the other classes. We explicitly disable
        // mirroring so the inference buffer matches the training frames.
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
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
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
