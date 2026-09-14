#!/usr/bin/env bash
# Convention guard — the things that caused drift before, enforced.
#
#   1. the hero exists once (templates/page.html); pages extend it
#   2. every page carries the hero archetype rather than hand-rolled headers
#   3. all CSS lives in static/style.css — no <style>, no style=""
#   4. type sizes come from the token scale, not literals (in declarations)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
templates="${here}/templates"
css="${here}/static/style.css"
fail=0

note() { printf '%-5s %s\n' "$1" "$2"; }

absent() { # description, pattern, allowed-file
  local desc="$1" pat="$2" allow="$3" hits
  hits="$(grep -rl -- "${pat}" "${templates}" 2>/dev/null | grep -v -x -- "${allow}" || true)"
  if [ -n "${hits}" ]; then
    note FAIL "${desc}"
    printf '      %s\n' ${hits}
    fail=1
  else
    note PASS "${desc}"
  fi
}

absent "hero markup lives only in templates/page.html" 'hero-text' "${templates}/page.html"
absent "avatar markup lives only in templates/page.html" 'class="avatar"' "${templates}/page.html"
absent "templates carry no <style> blocks" '<style' "/nonexistent"
absent "templates carry no inline style attributes" 'style="' "/nonexistent"

# Type sizes must reference the token scale. Strip the :root block first, since
# that is the one place a literal belongs.
if awk '/^:root \{/{s=1} !s{print} /^\}/{if(s)s=0}' "${css}" \
   | grep -qE 'font-size:[[:space:]]*[0-9.]+(rem|px)'; then
  note FAIL "font-size declarations use tokens (no raw rem/px outside :root)"
  awk '/^:root \{/{s=1} !s{print} /^\}/{if(s)s=0}' "${css}" \
    | grep -nE 'font-size:[[:space:]]*[0-9.]+(rem|px)'
  fail=1
else
  note PASS "font-size declarations use tokens (no raw rem/px outside :root)"
fi

if [ "${fail}" -eq 0 ]; then
  echo
  echo "conventions: OK"
else
  echo
  echo "conventions: FAILED"
fi
exit "${fail}"
