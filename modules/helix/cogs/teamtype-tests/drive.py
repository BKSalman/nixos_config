import subprocess, sys, time, json

def frame(obj):
    body = json.dumps(obj, separators=(',',':')).encode()
    return b"Content-Length: %d\r\n\r\n" % len(body) + body

URI = "file:///tmp/ttpg/file.txt"
msgs = [
    {"jsonrpc":"2.0","id":0,"method":"open",
     "params":{"content":"hello\nworld\n","uri":URI}},
    # byte-for-byte the payload the plugin's tests pinned down
    {"jsonrpc":"2.0","method":"edit","params":{
        "delta":[{"range":{"end":{"character":0,"line":1},
                           "start":{"character":0,"line":1}},
                  "replacement":"brave "}],
        "revision":0,"uri":URI}},
    {"jsonrpc":"2.0","method":"cursor","params":{
        "uri":URI,"ranges":[{"start":{"line":1,"character":0},
                             "end":{"line":1,"character":5}}]}},
]

p = subprocess.Popen([sys.argv[1], "client"], cwd="/tmp/ttpg",
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.DEVNULL)
for m in msgs:
    p.stdin.write(frame(m)); p.stdin.flush(); time.sleep(0.4)
time.sleep(1.0)
p.stdin.close()
out = p.stdout.read()
open("client-out.bin","wb").write(out)
print("captured %d bytes:" % len(out))
print(repr(out[:600]))
