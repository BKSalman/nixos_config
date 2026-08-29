# teamtype.scm tests

`./run.sh` builds `t.scm` — the plugin source with its Helix imports replaced by
the doubles in `stubs.scm`, followed by `fixture.scm` and `tests.scm` — and runs
it under the standalone `steel` interpreter. Set `STEEL=/path/to/steel` if it is
not on `PATH`.

Everything is concatenated into a single namespace rather than `require`d,
because the tests drive module-level state with `set!`.

`fixture.scm` holds bytes captured verbatim from a live `teamtype client`, so
the incoming path is exercised against real daemon output rather than
hand-written JSON. To regenerate it, or to re-check the outgoing path against a
real daemon:

```sh
mkdir -p /tmp/ttpg && chmod go-rwx /tmp/ttpg   # short path: unix sockets have a length limit
printf 'hello\nworld\n' > /tmp/ttpg/file.txt
teamtype share --no-join-code --directory /tmp/ttpg

python3 drive.py  "$(command -v teamtype)"   # sends open + edit, check /tmp/ttpg/file.txt
python3 drive2.py "$(command -v teamtype)"   # opens with divergent content -> writes client-in.bin
```

`stubs.scm` also stands in for a few `steel/process` names (`with-stdout`,
`with-stdin-piped`, ...) that exist in the Steel revision Helix embeds but not
in older standalone builds.
