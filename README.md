# mipre-comparator

Independent verification, via
[leanprover/comparator](https://github.com/leanprover/comparator), that the
[MIPRE-formalization](https://github.com/vidick/MIPRE-formalization) library proves
the main theorem of *MIP\* = RE* (Ji, Natarajan, Vidick, Wright, Yuen,
[arXiv:2001.04383](https://arxiv.org/abs/2001.04383), Theorem 12.2):

> **Halting reduces to the synchronous value of nonlocal games.**
>
> There is a computable map $g$ from Turing machines to (descriptions of) finite
> synchronous nonlocal games such that, for every machine $c$,
>
> * if $c$ halts on the empty input, the synchronous value of $g(c)$ is $1$;
> * if $c$ does not halt on the empty input, the synchronous value of $g(c)$ is at most $1/2$.

Machines are Mathlib's `Nat.Partrec.Code`, "halts on the empty input" is
`(c.eval 0).Dom`, and "computable" is Mathlib's `Computable`. The paper's
reduction is polynomial-time; this statement asks only that it be computable. The
value is the synchronous value: the supremum, over finite-dimensional synchronous
strategies (one projective measurement per question, measured in the normalized
trace state $\tau(M) = \mathrm{Tr}(M)/d$), of the winning probability.

## What to audit

Only [`Challenge.lean`](Challenge.lean), which imports **only Mathlib**. It
defines POVMs, synchronous games, synchronous strategies, the synchronous value
and a first-order description of games, and states the theorem with `sorry`.

`Challenge.lean` is the library's own statement file,
[`MIPRE/HaltingGameValue.lean`](https://github.com/vidick/MIPRE-formalization/blob/f7e08634f11e7ec233dd6dfb3c1aab76cb7d4b53/MIPRE/HaltingGameValue.lean),
unchanged except for the theorem appended at the end:

```bash
diff <(curl -sL https://raw.githubusercontent.com/vidick/MIPRE-formalization/f7e08634f11e7ec233dd6dfb3c1aab76cb7d4b53/MIPRE/HaltingGameValue.lean) Challenge.lean
```

If you believe `Challenge.lean` says the intended theorem, then a successful
comparator run certifies that the library proves it using only the standard
axioms:

```text
propext, Quot.sound, Classical.choice
```

[`Solution.lean`](Solution.lean) only imports `MIPRE.MainTheorem`, which proves
`HaltingGameValue.halting_reduces_to_gameValue`. The library declares the
challenge's definitions under the same names, in its Mathlib-only statement file,
and comparator checks that every declaration the statement uses is identical in
the two environments. Comparator rebuilds both modules in a sandbox — for
`Solution`, that means compiling the library from source at the commit pinned in
[`lakefile.toml`](lakefile.toml) — exports them with `lean4export`, compares the
statements, checks the axioms, and replays the proof through the Lean kernel.

## Run it

```bash
./verify.sh
```

This script is intended for Linux, WSL, or GitHub Actions. It downloads
`leanprover/comparator`, `lean4export`, and `landrun` pinned to this project's
Lean toolchain, fetches Mathlib's Lake cache, and runs the comparator check.
MIPRE-formalization itself is compiled from source, which takes the better part of
an hour on a four-core machine.

Expected final output:

```text
Your solution is okay!
```

## NixOS note

`landrun` needs the Nix store mounted read-only in its sandbox. The provided
script automatically adds `/nix/store` when it exists.
