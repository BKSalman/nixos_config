#!/usr/bin/env bash
# Tests for ../teamtype.scm. Requires the `steel` interpreter (STEEL=... to override).
set -euo pipefail
cd "$(dirname "$0")"

# Catches an unknown identifier, which in Steel is a compile error that takes
# the whole of helix.scm down with it -- the unit tests cannot see that, because
# they stub the Helix surface out.
python3 check-symbols.py

python3 build-t.py
exec ${STEEL:-steel} t.scm
