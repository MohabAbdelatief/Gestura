"""Render ad.html to PNG frames via CDP, then encode with ffmpeg."""
import base64, json, os, subprocess, sys, time, urllib.request, shutil
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'pylib'))
import websocket

HERE = os.path.dirname(os.path.abspath(__file__))
FPS = int(os.environ.get('FPS', '30'))
DUR = 15.0
FRAMES = int(FPS * DUR)
PORT = 9333
OUT = os.path.join(HERE, 'frames')
only = [float(x) for x in sys.argv[1:]]  # optional: render only these timestamps (for review)

BRAVE = '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'
prof = os.path.join(HERE, 'brave-profile')
proc = subprocess.Popen([BRAVE, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run',
                         f'--remote-debugging-port={PORT}', f'--user-data-dir={prof}',
                         '--window-size=1080,1920', 'about:blank'],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    for _ in range(100):
        try:
            tabs = json.load(urllib.request.urlopen(f'http://127.0.0.1:{PORT}/json')); break
        except Exception: time.sleep(0.2)
    page = next(t for t in tabs if t['type'] == 'page')
    ws = websocket.create_connection(page['webSocketDebuggerUrl'], suppress_origin=True)
    ws.settimeout(60)
    mid = 0
    def call(method, **params):
        global mid
        mid += 1
        ws.send(json.dumps({'id': mid, 'method': method, 'params': params}))
        while True:
            m = json.loads(ws.recv())
            if m.get('id') == mid:
                if 'error' in m: raise RuntimeError(m['error'])
                return m.get('result', {})
    call('Page.enable'); call('Runtime.enable')
    call('Emulation.setDeviceMetricsOverride', width=1080, height=1920, deviceScaleFactor=1, mobile=False)
    call('Page.navigate', url='file://' + os.path.join(HERE, 'ad.html') + '?render=1')
    time.sleep(1.5)
    call('Runtime.evaluate', expression='document.fonts.ready.then(()=>1)', awaitPromise=True)
    if only:
        os.makedirs(os.path.join(HERE, 'review'), exist_ok=True)
        for t in only:
            call('Runtime.evaluate', expression=f'seek({t})', awaitPromise=True)
            png = call('Page.captureScreenshot', format='png')['data']
            open(os.path.join(HERE, 'review', f't{t:05.2f}.png'), 'wb').write(base64.b64decode(png))
        print('review frames done')
    else:
        shutil.rmtree(OUT, ignore_errors=True); os.makedirs(OUT)
        t0 = time.time()
        for i in range(FRAMES):
            call('Runtime.evaluate', expression=f'seek({i/FPS})', awaitPromise=True)
            png = call('Page.captureScreenshot', format='png')['data']
            open(os.path.join(OUT, f'f{i:04d}.png'), 'wb').write(base64.b64decode(png))
            if i % 60 == 0: print(f'{i}/{FRAMES} {time.time()-t0:.0f}s', flush=True)
        print('frames done', time.time() - t0)
        mp4 = os.path.join(HERE, 'Gestura-ad-15s-1080x1920.mp4')
        subprocess.check_call(['ffmpeg', '-y', '-loglevel', 'error', '-framerate', str(FPS), '-i', os.path.join(OUT, 'f%04d.png'),
                               '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-crf', '17', '-preset', 'slow',
                               '-movflags', '+faststart', '-r', str(FPS), mp4])
        print('wrote', mp4)
finally:
    proc.terminate()
