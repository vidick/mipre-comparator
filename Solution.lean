import MIPRE.MainTheorem

/-!
# Solution

The proof lives in the [MIPRE-formalization](https://github.com/vidick/MIPRE-formalization)
library, at the commit pinned in `lakefile.toml`: `HaltingGameValue.halting_reduces_to_gameValue`
in `MIPRE/MainTheorem.lean`.

Nothing is restated here. `Challenge.lean` is the library's own statement file,
`MIPRE/HaltingGameValue.lean`, which imports only Mathlib, with the theorem appended. So the
challenge's definitions are declared in the library under the same names, and comparator checks
that each of them, and everything they refer to, is identical in the two environments.
-/
