# tile-lang status

The build implements milestone M1: the 12 generators of the design on
`U32` tiles of rank 2, their laws as `Eq` proofs, fused WGSL kernels and
GPU tests. M1 does not include `F32` cells, FlashAttention, general rank
or a check of the GPU device limits in the build. No later milestone is
planned.

## Implemented

- Type formers F1 to F15 (`formers/tcc-webgpu.md`). F15 works in
  `domain/` only, and the tile-lang domain declares no family.
- Core types `U32` and `Tile r c U32` (host primitives).
- The 12 generators of `domain/domain.lang`: `copy`, `tmap`, `fill`,
  `tadd`, `tsub`, `tmul`, `gemm`, `gemmAcc`, `reduce`, `view`, `tr` and
  `kernel` (T1).
- The refusal of the kit basis in a program (`REFUSE_BASIS`, T1).
- The laws as `Eq` proofs: `examples/tile-laws.lang` has 35 proofs, 23
  on closed tiles and 12 on open terms (T2).
- Kernels: `examples/kernels.lang` has 13 entries, and
  `examples/fused.lang` has 7 fused entries: axpy, a dot product, a
  product reduce, GEMM, blocked GEMM through the kernel grid, and the
  attention core without softmax in two orders (T3). Each entry is one
  WGSL pass with no intermediate buffer.
- The outputs `NAME.wgsl`, `NAME.js` and `NAME.json`.

## FlashAttention

FlashAttention is not in M1. The element ruling gives `U32` and `Flag`
cells only, with no `F32`. Softmax needs exp, max and division, and
`U32` has no compare and no division. Thus tile-lang cannot express
softmax. `examples/fused.lang` has the attention core without softmax:
`attnE` is `(Q K^T) V`, `linE` is `Q (K^T V)`, and the two give the same
tile.

## Remaining work

1. `F32` cells and softmax for FlashAttention (O4). This needs a new
   element ruling and new kit primitives.
2. General rank (O3). This needs a shape as a list of `Nat` in the kit.
3. A proof that a user `reduce` op is associative (O7).
4. Offline WGSL validation (O2). This needs a new tool (naga-cli). The
   default is Deno on a GPU.
5. Generators for `Flag` tiles. No generator makes or reads a `Flag`
   tile.
6. An eta rule for tiles in the checker. It would make the H1 rows of
   the law table DONE.
7. A build check for the limits L1 and L2. This needs a change to the
   host kit `hosts/tcc-webgpu` in lang-template.

## Host limits of the laws (T2)

Each law is an `Eq` proof by `refl`. The checker proves it by
normalization. The table gives the status of each law on closed tiles,
on open tiles with a closed shape, and on an open shape. HOST-LIMIT
codes H1 to H4 mark the forms that the checker cannot prove. Each gives
`TYPE_REFL`. No row is PLANNED.

| Law | Closed tiles | Open tiles, closed shape | Open shape |
|---|---|---|---|
| `copy t = t` | DONE | DONE | DONE |
| `tmap` identity | DONE | H1 | H1 |
| `tmap` composition | DONE | DONE | H2 |
| `view` of a `view` | DONE | DONE (open offsets: H4) | H2 |
| Identity `view` | DONE | H1 (eta form DONE) | H4 |
| `tr` of `tr` | DONE | H1 (eta form DONE) | H2 |
| `tr` of a `view` | DONE | DONE | H2 |
| `gemm` linear on the left and on the right, scalar left and right, associative | DONE | H3 | H2 |
| `gemmAcc z a b = tadd z (gemm a b)` | DONE | DONE | DONE |
| `kernel` tiling identity | DONE | H1 (eta form DONE) | H2 |
| `kernel` of `tadd` of views, `kernel` of `tmap` of views, `kernel` of `tadd` is `tadd` of kernels | DONE | DONE | H2 |
| `u32Add` and `u32Mul` associative (O7) | DONE | H3 | None |
| `reduce` of `tadd`, `reduce` of `tr` (O7) | DONE | H3 | H2 |

| Code | Cause |
|---|---|
| H1 | The checker has no eta rule for tiles. For an open tile `t`, the normal form of the left side is a grid of cells of `t`, not `t`. |
| H2 | At an open shape, an `at` of a `tabulate` does not reduce. |
| H3 | The checker does not normalize open `U32` ring terms. |
| H4 | `natAdd` and `natMul` do not reduce on an open `Nat`. |

## Known limits

- L1, binding numbers. The WGSL writer numbers the bindings across all
  entries of a program in group 0, with no cap. The ES module calls
  `requestDevice()` with the default limits (`maxBindingsPerBindGroup`
  1000) and the layout `'auto'`. Thus an entry with a binding of 1000 or
  more fails when the module creates its pipeline. A GPU probe confirmed
  this on 2026-10-11: in a program with 600 `copy` entries, entry `e599`
  (binding 1198) gives the GPUPipelineError "Unable to derive an implicit
  layout: Binding index 1198 is greater than the maximum number 1000".
  The build does not refuse such a program, so the failure comes only at
  run time. An entry has at most 8 bindings (7 parameters and the
  result), so a program with 125 entries or fewer is safe. The largest
  binding is 30 in `examples/kernels.lang` and 22 in
  `examples/fused.lang`. The fix is a change to the host kit.
- L2, dispatch size. The dispatch is 1-D: the cells of the result
  divided by 64, rounded up. The WebGPU default
  `maxComputeWorkgroupsPerDimension` is 65535, so a result with more
  than 4194240 cells would fail. The writer refuses a tile with more
  than 1048576 cells (`WGSL_FORM`), so a built entry does not reach this
  limit. Not probed on a GPU.
- An entry has at most 7 parameters and 64 bound variables. A tile in an
  entry has at most 1048576 cells. The workgroup size is 64.
- The WGSL bounds check is sound but not complete. The writer can refuse
  an entry that `langc check` and `langc eval` accept.
- `langc eval` cannot take a `U32` or a tile argument. A test of a tile
  is an `Eq` definition on closed tiles.
- The evaluator has a fuel budget of 20,000,000 steps for each instance
  and a depth limit of 2000. `docs/host/README.md`, section Limits, gives
  all limits.

## Internal boundaries

`src/front/` holds the lexer, the parser, the checker and the
evaluator. The checker holds the refusals. `src/front/check.c` holds the
kit basis list and refuses a basis name in a program (`REFUSE_BASIS`).
`test/parse/` and `test/check/` hold the refused programs and their
codes.

`domain/domain.lang` holds the 12 generators. `gen/embed.c` embeds it
in `build/langc` at build time. It is the only file that can name the
kit basis or declare a family.

`src/wgsl.c` writes the WGSL module and the text of the kernels
manifest. It refuses an entry with `BOUNDS` or `WGSL_FORM`. `test/wgsl/`
holds the golden modules, and `test/emit/` holds the refused entries.
`src/json.c` writes the JSON document, and `test/json/` holds its
goldens. `src/js.c` writes the ES module with the guest tests and the
GPU tests. `src/main.c` holds the commands.

A program cannot use the kit basis, declare a family, use an `F32`
cell, or make or read a `Flag` tile through a generator.
