# Validation

Date: 2026-10-11. TinyCC: 0.9.28rc (mob@0fb54300, AArch64 Darwin).
Node: 23.10.0. Deno: 2.9.3. Host executable: `build/langc`, built by
`make check` from commit c958404 and the T4 documents. The documents do
not change the executable.

`make check` passes. It builds `build/langc` and
`build/backend-regressions` with TinyCC. It compiles the sources with
`cc -Wall -Wextra -Wswitch-enum -Werror -fsyntax-only`. Then it runs the
backend regressions, `test/gate.sh`, `test/regressions.js` and
`test/printer-regressions.js`. The gate reports 0 failures.

## Gate lines

| Line | Count | What it checks |
|---|---|---|
| backend regressions | 52 | `test/backend-regressions.c`: C checks of the writers |
| examples | 15 | `langc check` accepts each `examples/*.lang` |
| parse refusals | 13 | Each file in `test/parse/` gives the code in `test/parse/expect.txt` |
| check refusals | 40 | Each file in `test/check/` gives the code in `test/check/expect.txt` |
| evals | 33 | Each line of `test/eval/expect.txt` gives its normal form or its code |
| json | 15 | Each example builds to its golden in `test/json/`, and each golden parses |
| wgsl | 15 | Each example builds with `--wgsl`. The modules of `kernels.lang` and `fused.lang` and the header-only module agree with `test/wgsl/` |
| build refusals | 2 | Each file in `test/emit/expect.txt` gives its code and no output |
| wgsl refusals | 10 | Each `test/emit/wgsl-*.lang` gives the code in `test/emit/wgsl.txt`, and a refused build writes nothing |
| js | 15 | Each example builds with `--js --selftest`, its guest tests pass in Node, and `encode(document)` agrees with the JSON golden |
| js wgsl | 15 | The WGSL text in each ES module agrees with `langc build --wgsl` |
| js gpu | 15 | Each module built with `--gpu` runs in Node with no adapter. A module with GPU tests must stop with "N GPU tests and no GPU adapter" (13 for `kernels.lang`, 12 for `fused.lang`). A module without GPU tests must pass. |
| js evals | 13 | Each eval line whose name is an entry gives the same value through the JS entries (20 lines are not entries) |
| js build refusals | 15 | Each refused build also refuses with `--js` |
| regressions | 6 | `test/regressions.js`: type safety, type metadata, binder scope and domain declarations |
| printer regressions | 2 | `test/printer-regressions.js`: the type and normal-form printer |

## Slices

T1 adds `examples/tiles.lang` with `Eq` tests over the 12 generators.
`reduceOrder` proves the row order of `reduce`. `examples/kernels.lang`
has 13 entries: 10 over the generators (`copy`, `tmap`, `tadd`, a scale,
`gemm`, `gemmAcc`, `reduce`, `view`, `tr` and `kernel`) and 3 with an
empty shape. Its 13 `Eq` tests are 13 GPU tests. Refusals cover each
name of the kit basis, applied or bare (`test/check/basis-*.lang`,
`REFUSE_BASIS`), a variable element type (`TILE_ELEM`) and a program
that redefines a generator (`REFUSE_NAME`). `test/emit/` covers the
entries that WGSL cannot hold (`BOUNDS`, `WGSL_FORM`).

T2 adds `examples/tile-laws.lang` with 35 `Eq` proofs, each by `refl`:
23 laws on closed tiles and 12 laws on open terms. `docs/STATUS.md`
gives the law table and the HOST-LIMIT codes H1 to H4. The file has no
entry, so it has no GPU test. A kill check changed 4 laws (a `view`
offset, a `gemm` argument, a `reduce` seed and a `gemm` scalar). The
checker refused each mutant with `TYPE_REFL` (4 of 4 killed). The
mutants are not in the repository.

T3 adds `examples/fused.lang` with 7 entries (`axpyE`, `dotE`, `prodE`,
`gemmE`, `blockedE`, `attnE` and `linE`) and 12 `Eq` tests. Each test is
a GPU test. The expected values come from closed formulas. `blockedE`
gives the same tile as `gemmE`, and `attnE` gives the same tile as
`linE`. Factors near 2^32 make the products wrap. `blockedE` is
`kernel 2 2 2 2` of `gemmAcc` over two blocks of `k`. Its WGSL is one
pass with two loops and no intermediate buffer. A kill check changed 5
entries or tests (the `k` offset of `blockedE`, a `k` to `q` in `linE`,
the `prodE` seed, `x` to `y` in `axpyE`, and `tmul` to `tadd` in `dotE`).
The checker refused each mutant with `TYPE_REFL` (5 of 5 killed).

## GPU check

`make gpu-check` builds each example with `--js --selftest --gpu` and
runs the module under Deno with `--unstable-webgpu`. It needs a GPU
adapter, so it is not part of `make check` and does not run in a
sandbox. Run it by hand on a machine with a GPU. The last run was on
2026-10-11, after T3: 15 modules ran with no error. The 13 GPU tests of
`kernels.lang` and the 12 GPU tests of `fused.lang` agree with the C
evaluator.
