"""Synthesize an original 15 s soundtrack for the Gestura ad (pure Python, no deps)."""
import math, random, wave, struct, os
SR = 44100; DUR = 15.0; N = int(SR*DUR)
buf = [0.0]*N
random.seed(3)
BPM = 124; BEAT = 60/BPM

def add(t0, samples, gain=1.0):
    i0 = int(t0*SR)
    for k, v in enumerate(samples):
        j = i0+k
        if 0 <= j < N: buf[j] += v*gain

def env(n, a, d, sustain=0.0):
    out = []
    for k in range(n):
        t = k/SR
        if t < a: out.append(t/a)
        else: out.append(max(sustain, math.exp(-(t-a)/d)))
    return out

def kick(t0):
    n = int(0.35*SR); out = []; ph = 0
    for k in range(n):
        t = k/SR; f = 45 + 120*math.exp(-t*28); ph += 2*math.pi*f/SR
        out.append(math.sin(ph)*math.exp(-t*9)*1.0)
    add(t0, out, 0.9)

def hat(t0, open_=False):
    n = int((0.16 if open_ else 0.045)*SR)
    out = [(random.random()*2-1)*math.exp(-k/SR*(18 if open_ else 70)) for k in range(n)]
    # crude high-pass: first difference
    out = [out[k]-out[k-1] if k else 0 for k in range(n)]
    add(t0, out, 0.22 if open_ else 0.28)

def pluck(t0, f, dur, gain, bright=0.5):
    n = int(dur*SR); e = env(n, 0.004, dur*0.35); out = []
    for k in range(n):
        t = k/SR
        v = math.sin(2*math.pi*f*t) + bright*0.5*math.sin(2*math.pi*2*f*t)*math.exp(-t*8) + bright*0.25*math.sin(2*math.pi*3*f*t)*math.exp(-t*14)
        out.append(v*e[k])
    add(t0, out, gain)

def pad(t0, freqs, dur, gain):
    n = int(dur*SR); out = [0.0]*n
    a = 0.6; rel = 0.5
    for f in freqs:
        for det in (-0.4, 0.4):
            ff = f*(1+det/100); ph = random.random()*6.28
            for k in range(n):
                t = k/SR
                out[k] += math.sin(2*math.pi*ff*t+ph) + 0.3*math.sin(2*math.pi*2*ff*t+ph)
    for k in range(n):
        t = k/SR
        e = min(1, t/a) * (1 if t < dur-rel else max(0, (dur-t)/rel))
        out[k] *= e
    add(t0, out, gain/len(freqs)/2)

def blip(t0):  # gesture recognized: two rising tones
    for i, f in enumerate((880, 1318.5)):
        n = int(0.18*SR)
        out = [math.sin(2*math.pi*f*k/SR)*math.exp(-k/SR*14)*(1 if k > 60 else k/60) for k in range(n)]
        add(t0+i*0.09, out, 0.45)

def whoosh(t0, dur=0.5):
    n = int(dur*SR); out = []; prev = 0
    for k in range(n):
        t = k/SR; x = t/dur
        amp = math.sin(math.pi*x)**2 * (0.3+0.7*x)
        noise = random.random()*2-1
        prev = prev*0.92 + noise*0.08*(1+6*x)  # opening low-pass
        out.append(prev*amp)
    add(t0, out, 0.9)

def note(name, octave):
    names = {'C':0,'C#':1,'D':2,'D#':3,'E':4,'F':5,'F#':6,'G':7,'G#':8,'A':9,'A#':10,'B':11}
    return 440*2**((names[name]-9)/12 + (octave-4))

prog = [('A',['A','C','E']), ('F',['F','A','C']), ('C',['C','E','G']), ('G',['G','B','D'])]
BAR = 4*BEAT
music_start = 3.1
# pads through the whole piece from the reveal to the end
for i in range(int((DUR-music_start)/BAR)+1):
    t0 = music_start + i*BAR
    root, tri = prog[i % 4]
    pad(t0, [note(n, 3 if n in ('A','G','F') and j == 0 else 4) for j, n in enumerate(tri)], BAR+0.6, 0.20)
    # bass on 8ths
    for e in range(8):
        pluck(t0+e*BEAT/2, note(root, 1 if root != 'C' else 2), 0.42, 0.55 if e % 2 == 0 else 0.35, bright=0.35)
    # arp on 16ths (demo scene onward)
    if t0 >= 5.4:
        seq = tri + [tri[1]]
        for e in range(16):
            n = seq[e % 4]; oc = 5 if e % 8 < 4 else 6
            pluck(t0+e*BEAT/4, note(n, oc), 0.22, 0.16, bright=0.6)
# drums: soft hats from the reveal, full kick from the demo scene
for b in range(int(DUR/BEAT)+1):
    t0 = b*BEAT
    if t0 < music_start or t0 > 14.4: continue
    if t0 >= 5.4: kick(t0)
    hat(t0+BEAT/2, open_=(b % 4 == 3))
    if t0 >= 5.4: hat(t0)
# hook: a sparse heartbeat pulse under the words
for t0 in (0.15, 0.55, 0.95, 1.55):
    kick(t0)
# transitions & recognitions
for t0 in (3.05, 5.45, 11.75, 13.45): whoosh(t0-0.35)
for t0 in (7.0, 8.9, 10.7): blip(t0)
# final hit on the end card
kick(14.05); pad(14.05, [note('A',3), note('C',4), note('E',4), note('A',4)], 1.0, 0.25)

out = []
for k in range(N):
    t = k/SR
    g = min(1, t/0.05) * (1 if t < 14.4 else max(0, (15-t)/0.6))
    v = math.tanh(buf[k]*1.1*g)
    out.append(int(max(-1, min(1, v))*32000))
w = wave.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'soundtrack.wav'), 'wb')
w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
w.writeframes(b''.join(struct.pack('<hh', v, v) for v in out)); w.close()
print('wrote soundtrack.wav')
