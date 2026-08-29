import json, sys, glob
sys.path[:0] = glob.glob('pyte-result/lib/python*/site-packages') + \
               glob.glob('/nix/store/*wcwidth-0.8.2/lib/python*/site-packages')
import pyte

hdr = None
events = []
for i, ln in enumerate(open('/tmp/tt2/repro', encoding='utf-8', errors='replace')):
    ln = ln.strip()
    if not ln: continue
    if hdr is None:
        hdr = json.loads(ln); continue
    try: ev = json.loads(ln)
    except Exception: continue
    if len(ev) >= 3 and ev[1] == 'o':
        events.append((ev[0], ev[2]))

cols, rows = hdr['term']['cols'], hdr['term']['rows']
class Tolerant(pyte.Screen):
    # kitty/zellij emit private-parameter CSI forms pyte does not model
    def report_device_status(self, *a, **kw): pass
    def write_process_input(self, *a, **kw): pass

screen = Tolerant(cols, rows)
stream = pyte.Stream(screen)

def snapshot():
    return [l.rstrip() for l in screen.display]

prev_marker = None
t = 0.0
for delay, chunk in events:
    t += delay
    stream.feed(chunk)
    disp = snapshot()
    hits = [(r, l.index('▏'), l) for r, l in enumerate(disp) if '▏' in l]
    key = tuple((r, c) for r, c, _ in hits)
    if key != prev_marker:
        prev_marker = key
        print(f"\n=== t={t:6.2f}  hint at {list(key)}")
        lo = max(0, min((h[0] for h in hits), default=0) - 3)
        hi = min(len(disp), max((h[0] for h in hits), default=0) + 4)
        for r in range(lo, hi):
            mark = '>>' if any(h[0] == r for h in hits) else '  '
            print(f"{mark}{r:3d}| {disp[r]}")
