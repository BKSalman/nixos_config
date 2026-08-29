#!/usr/bin/env python3
"""Verify every identifier teamtype.scm references actually exists.

Steel reports an unknown identifier as a compile-time FreeIdentifier, which
takes the whole of helix.scm down with it -- so a typo or a function that only
exists in a newer Steel is a total load failure, not a degraded feature. The
unit tests cannot catch that: they stub the Helix surface out.
"""
import os, re, subprocess, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(HERE, '..', 'teamtype.scm')
STEEL = os.environ.get('STEEL', 'steel')
LSP = os.path.expanduser('~/.steel/lsp')

src = open(SRC).read()
body = re.sub(r';[^\n]*', '', src)                    # comments
body = re.sub(r'"(?:[^"\\]|\\.)*"', '""', body)      # string literals

# Names the module defines itself, plus its own binding forms.
defined = set(re.findall(r'\(define\s+\(([^\s)]+)', body))
defined |= set(re.findall(r'\(define\s+([^\s()]+)', body))
locals_ = set()
for grp in re.findall(r'\(lambda\s*\(([^)]*)\)', body):        # lambda params
    locals_ |= set(grp.replace('.', ' ').split())
for grp in re.findall(r'\(define\s+\(([^)]*)\)', body):        # define params
    locals_ |= set(grp.replace('.', ' ').split()[1:])
locals_ |= set(re.findall(r'\[\s*([a-zA-Z][^\s\]]*)\s', body))     # let bindings
locals_ |= set(re.findall(r'\(let\s+([a-zA-Z][^\s(]*)\s*\(', body))  # named let

SPECIAL = {
 'define','lambda','let','let*','letrec','if','cond','else','when','unless','begin',
 'set!','quote','quasiquote','and','or','case','do','delay','provide','require',
 'require-builtin','prefix-in','only-in','define-syntax','syntax-rules','~>','~>>',
 'with-handler','return!','for-each','λ','#%module','let-values','define-values',
}

# `/` is legal in Steel names (bytes->string/utf8), so keep it and drop the
# module paths from the require lines separately.
body_norequire = re.sub(r'\(require[^\n]*\n', '\n', body)
tokens = set(re.findall(r"[(\s\[]([a-zA-Z][a-zA-Z0-9>!?*<=/_.+-]*)", body_norequire))
tokens = {t for t in tokens if not t.endswith('.')}   # module prefixes, not names
cands = sorted(t for t in tokens
               if t not in defined and t not in locals_ and t not in SPECIAL
               and not t.startswith('#') and not re.match(r'^[0-9]', t))

helix_names = set()
for f in glob.glob(os.path.join(LSP, '_helix-*.scm')):
    helix_names |= set(re.findall(r"[('\s]([a-zA-Z][a-zA-Z0-9>!?*_./-]*)", open(f).read()))

missing_helix, steel_cands = [], []
for c in cands:
    if c.startswith('helix.'):
        bare = c.split('.', 2)[-1]
        (steel_cands if bare in helix_names else missing_helix).append(c)
    else:
        steel_cands.append(c)

# Ask Steel itself about the rest, using the module's own imports.
HEAD = '\n'.join(l for l in src.splitlines()
                 if l.startswith('(require-builtin') and 'helix' not in l) + \
       '\n(require "steel/result")\n'
probe = os.path.join(HERE, '.symcheck.scm')
unknown, pool = [], [c for c in steel_cands if not c.startswith('helix.')]
for _ in range(60):
    if not pool: break
    open(probe, 'w').write(HEAD + ''.join(f'{c}\n' for c in pool))
    r = subprocess.run(STEEL.split() + [probe], capture_output=True, text=True)
    if r.returncode == 0: break
    m = re.search(r'Cannot reference an identifier before its definition:\s*(\S+)', r.stderr + r.stdout)
    if not m:
        print("unexpected steel output:\n", (r.stderr or r.stdout)[:600]); break
    name = m.group(1).split('.')[-1]
    hit = next((c for c in pool if c == name or c.endswith('.' + name)), None)
    if hit is None:
        print("could not map reported name:", m.group(1)); break
    unknown.append(hit); pool.remove(hit)
if os.path.exists(probe): os.remove(probe)

# Present in the Steel revision Helix embeds, absent from older standalone
# builds; verified by hand against steel-core's process module.
NEWER_STEEL = {'with-stdout', 'with-stderr', 'with-stdin-piped', 'with-current-dir'}
# Provided by Helix cogs (picker.scm and friends), invisible to standalone steel.
COG_NAMES = {'picker-selection'}
unknown = [u for u in unknown
           if u not in helix_names and u not in NEWER_STEEL and u not in COG_NAMES]

print(f"checked {len(cands)} identifiers")
for m in missing_helix: print("  MISSING (helix):", m)
for u in unknown:       print("  UNRESOLVED:", u)
if missing_helix or unknown:
    sys.exit(1)
print("all identifiers resolve")
