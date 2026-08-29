import re
src = open('../teamtype.scm').read()
for d in ['(require-builtin helix/core/text)',
          '(require "helix/editor.scm")',
          '(require (prefix-in helix.static. "helix/static.scm"))',
          '(require "helix/misc.scm")',
          '(require "picker.scm")',
          '(require-builtin steel/process)']:
    src = src.replace(d, ';; ' + d)
src = re.sub(r'\(provide\n(?:.*\n)*?.*teamtype-tick-interval!\)\n', '', src, count=1)
stubs = open('stubs.scm').read()
tests = open('fixture.scm').read() + open('tests.scm').read()
# Inlined rather than required: the tests drive module-level state with set!,
# which only works if everything shares one namespace.
open('t.scm','w').write(stubs + src + tests)
print("built t.scm")
