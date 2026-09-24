#!/usr/bin/env bash
# Independently verify the solution with leanprover/comparator.
#
# Trust required: the Lean kernel, Mathlib, Challenge.lean (the statement), lakefile.toml,
# and comparator itself. The proof in MIPRE-formalization does not need to be trusted
# directly; comparator checks it independently.
set -euo pipefail

TOOLCHAIN_TAG=$(sed -e 's/^leanprover\/lean4://' lean-toolchain | tr -d '[:space:]')
WORK="${COMPARATOR_WORK:-$HOME/.cache/mipre-comparator}"
mkdir -p "$WORK"

if [ ! -d "$WORK/comparator" ]; then
  git clone --branch "$TOOLCHAIN_TAG" --depth 1 \
    https://github.com/leanprover/comparator "$WORK/comparator"
fi
if [ ! -d "$WORK/lean4export" ]; then
  git clone --branch "$TOOLCHAIN_TAG" --depth 1 \
    https://github.com/leanprover/lean4export "$WORK/lean4export"
fi
(cd "$WORK/comparator" && lake build)
(cd "$WORK/lean4export" && lake build)

# landrun, wrapped to grant dynamic loader paths that its -ldd resolution can
# miss. This mirrors the comparator reference setup and supports NixOS too.
if [ ! -x "$WORK/landrun-bin" ]; then
  curl -sL -o "$WORK/landrun-bin" \
    https://github.com/Zouuup/landrun/releases/download/v0.1.14/landrun-linux-amd64
  chmod +x "$WORK/landrun-bin"
fi
EXTRA=""
for d in /lib64 /lib /usr/lib /nix/store; do
  [ -e "$d" ] && EXTRA="$EXTRA --rox $d"
done
printf '#!/usr/bin/env bash\nexec "%s/landrun-bin"%s "$@"\n' "$WORK" "$EXTRA" \
  > "$WORK/landrun"
chmod +x "$WORK/landrun"
export COMPARATOR_LANDRUN="$WORK/landrun"
export PATH="$WORK:$PATH"

export PATH="$WORK/lean4export/.lake/build/bin:$PATH"

# nanoda, an independent type checker written in Rust: comparator runs it on the
# exported solution in addition to the Lean kernel (`enable_nanoda` in
# comparator.json). Pinned; it reads lean4export's format 3.1.0, which is what
# lean4export v4.33.0 writes. Needs cargo.
NANODA_REV=3a2407216ee84a75f9e1aead6803d0578be06ae7 # nanoda_lib 0.4.19
if [ ! -x "$WORK/nanoda_lib/target/release/nanoda_bin" ] \
    || [ "$(git -C "$WORK/nanoda_lib" rev-parse HEAD 2>/dev/null)" != "$NANODA_REV" ]; then
  rm -rf "$WORK/nanoda_lib"
  git init -q "$WORK/nanoda_lib"
  git -C "$WORK/nanoda_lib" fetch -q --depth 1 https://github.com/ammkrn/nanoda_lib "$NANODA_REV"
  git -C "$WORK/nanoda_lib" checkout -q FETCH_HEAD
  (cd "$WORK/nanoda_lib" && cargo build --release --locked)
fi
export COMPARATOR_NANODA="$WORK/nanoda_lib/target/release/nanoda_bin"

# Mathlib's cache only: MIPRE-formalization itself is compiled from source, inside
# comparator's sandbox, when comparator builds `Solution`.
lake exe cache get
# nanoda checks on its main thread, and this proof has some very deep terms:
# lift the 8 MB default stack limit for everything comparator starts.
ulimit -s unlimited 2>/dev/null || ulimit -s "$(ulimit -Hs)"
lake env "$WORK/comparator/.lake/build/bin/comparator" comparator.json
