import subprocess, sys, time, json
def frame(obj):
    body = json.dumps(obj, separators=(',',':')).encode()
    return b"Content-Length: %d\r\n\r\n" % len(body) + body
URI = "file:///tmp/ttpg/file.txt"
# The daemon holds "hello\nbrave world\n". Open with something else: per the
# protocol it must send edits back to bring us onto its version.
msgs = [{"jsonrpc":"2.0","id":0,"method":"open",
         "params":{"content":"hello\nDIFFERENT TEXT\n","uri":URI}}]
p = subprocess.Popen([sys.argv[1], "client"], cwd="/tmp/ttpg",
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=subprocess.DEVNULL)
for m in msgs:
    p.stdin.write(frame(m)); p.stdin.flush()
time.sleep(1.5); p.stdin.close()
out = p.stdout.read()
open("client-in.bin","wb").write(out)
print("captured %d bytes" % len(out)); print(repr(out))
