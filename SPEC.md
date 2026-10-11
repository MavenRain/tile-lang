# tile-lang specification

Status: milestone M1 is complete (slices T0 to T4, 2026-10-11).
`docs/STATUS.md` gives the limits and the open work.

## 1. Purpose

A tile-lang program describes pure functions on tiles. A tile is a
function from a finite index shape of rank 2 to `U32` cells
(`design/DESIGN.md`, section Semantic model). The compiler checks the
program and evaluates its definitions. Then it writes a WGSL module, an
ES module and a JSON document (section 7).

The host is TinyCC: the compiler is C, and TinyCC builds it into
`build/langc`. The target is WebGPU.

The core types and the core operations are only those of
`design/DESIGN.md`. The type formers are F1 to F15 of
`formers/FORMERS.md`. A program cannot add a type former, a data type or
a generator.

## 2. Programs

A program is a sequence of definitions:

```
def NAME : TYPE := TERM
```

The compiler refuses a program with one of these forms:

| Code | Form |
|---|---|
| `REFUSE_DATA` | The program declares a data type or a family. Only `domain/domain.lang` can declare a family (rule R1). |
| `REFUSE_AXIOM` | The program declares an axiom (a fact without a proof). |
| `REFUSE_REC` | A definition names itself or a later definition. |
| `REFUSE_NAME` | A definition uses a core name, a domain name, a reserved name or a name that the program already defines. |
| `REFUSE_BASIS` | The program names the kit basis: `tabulate`, `at`, `sumTo`, `foldTo`, `natDiv` or `natMod`, applied or bare. |
| `TILE_ELEM` | A tile has an element type that is not `U32` or `Flag`. |

Thus a program cannot add a data type, an unproved fact or general
recursion. Recursion comes only from `fold` and `unfold` (F6, F7). A
program makes and changes tiles only with the generators of section 6.
It cannot read one cell of a tile. A program has no fixed first
definition: each generator takes its shape as `Nat` arguments.

The compiler writes the target. A program cannot.

## 3. Type formers

The type formers are F1 to F15 of `formers/FORMERS.md`. This language
uses the tcc-webgpu column of the realization matrix.
`formers/tcc-webgpu.md` gives the host form and the status of each
former. Each former is DONE. This table gives the deviations only.

| ID | Status on tcc-webgpu | Effect on this language | Open item |
|---|---|---|---|
| F15 | DONE in `domain/` only | The tile-lang domain declares no family, and a program cannot declare one. | None |
| F9, F10, F12, F13, F14 | DONE | A WGSL entry body cannot hold a function, a type or an `Eq` value (`WGSL_FORM`). | None |

## 4. Structures

The generators do not use the Monad, Algebra or Filterable structures on
tiles. A tile is not a carrier of these structures. The structures stay
on the carriers of the kit:

- **Monad**: `pure`, `map`, `bind` on Option, `Sum E` and List.
- **Algebra**: `fold` on Nat, List and each family. `unfold` into List
  with a Nat step limit.
- **Filterable**: `filter` on Option and List.

The functor action on tiles is the generator `tmap` (section 6). The kit
has the name `map`, so the generator has a different name.

## 5. Core types

| Type | Meaning (design section) | Definition |
|---|---|---|
| `U32` | The element type `A` of `Tile_S A` (Semantic model) | Host primitive. A number modulo 2^32, written `5u`. `u32Add`, `u32Sub` and `u32Mul` wrap modulo 2^32. `U32` has no compare, no division and no conversion to `Nat`. Probe-forced: the element ruling gives no `F32`. |
| `Tile r c U32` | `Tile_S A = S -> A` with `S = [0, r) x [0, c)` (Semantic model) | Host primitive `Tile R C A`. Rank 2 only (O3). The shape `r`, `c` is a `Nat` term, and the checker compares shapes by normalization. Each generator takes and gives `U32` cells. |
| `Flag` | A mask cell (element ruling) | Host primitive with `flagYes`, `flagNo` and `flagIf`. The checker accepts a `Flag` tile, but no generator makes or reads one. |
| Kernel | A pure function from input tiles to output tiles (Semantic model) | An entry (section 7). |

`Nat` gives the shapes and the indices. A program can use `natAdd`,
`natSub`, `natMul`, `natEq` and `natLe`. Only the domain can use `natDiv`
and `natMod`. No operation converts a `U32` cell to `Nat`, so a `Nat`
operation cannot act on a cell.

## 6. Core operations

The operations are the 12 generators of `domain/domain.lang`. Each
generator takes its shape arguments first. In the type column, `T r c`
is `Tile r c U32`.

| Operation | Type | Meaning (design section) |
|---|---|---|
| `copy r c t` | `T r c -> T r c` | copy: the identity transport, `[[copy t]] = [[t]]` |
| `tmap r c f t` | `(U32 -> U32) -> T r c -> T r c` | map: `f` after `t` |
| `fill r c x` | `U32 -> T r c` | allocation: a tile that is initially constant |
| `tadd r c x y`, `tsub r c x y`, `tmul r c x y` | `T r c -> T r c -> T r c` | the pointwise structure of the function space |
| `gemm m k n a b` | `T m k -> T k n -> T m n` | gemm: cell `(i, j)` is the sum over `l` of `a(i, l) * b(l, j)` |
| `gemmAcc m k n z a b` | `T m n -> T m k -> T k n -> T m n` | gemm, the accumulate form: `tadd z (gemm a b)` |
| `reduce r c op e t` | `(U32 -> U32 -> U32) -> U32 -> T r c -> T 1 1` | reduce: the left fold of `op` from `e` over the cells of `t` in row order. `op` must be associative (O7). |
| `view r c r0 c0 rs cs m n t` | `T r c -> T m n` | view: `t` after the affine embedding `(i, j) -> (r0 + rs * i, c0 + cs * j)` |
| `tr r c t` | `T r c -> T c r` | view: the transpose, the other affine embedding of rank 2 |
| `kernel g1 g2 t1 t2 f` | `(Nat -> Nat -> T t1 t2) -> T (natMul g1 t1) (natMul g2 t2)` | Kernel / grid: the product over the `g1` by `g2` grid of blocks. Block `(i / t1, j / t2)` gives the cell `(i mod t1, j mod t2)`. |

A program composes the generators with function application, `fun` and
`def`. Kernel composition is function composition.

## 7. Target and instance encoding

`langc build` writes three outputs. `docs/host/README.md` gives the full
forms.

**Entries.** An entry is a definition of the program (not of `domain/`)
whose type normalizes to a function type with one or more parameters
and a tile result. Each parameter is a tile or a `U32`. Each tile has a
closed shape. The WGSL writer ignores the other definitions. An entry
with more than 7 parameters refuses the whole build with `WGSL_FORM`,
including a build that requests only JSON or JS.

**`NAME.wgsl`** (`--wgsl`). The module has one
`@compute @workgroup_size(64)` function for each entry. Parameter `P` is
the read-only storage buffer `ENTRY_inP`, and the result is the storage
buffer `ENTRY_out`. All bindings are in group 0. One invocation writes
one result cell, at index `i * C + j` (row-major order). The writer fuses
the generators of an entry into one pass with no intermediate buffer.
`u32Add`, `u32Sub` and `u32Mul` wrap modulo 2^32, as in the C evaluator.
The writer refuses an entry with `BOUNDS` (an index can leave its tile)
or `WGSL_FORM` (the entry has no WGSL form). A program without entries
gives a module with the header only.

**`NAME.js`** (`--js`). An ES module that evaluates the program in JS
and runs the entries on a WebGPU device. The same module runs in a
browser and in Deno. `--selftest` adds the guest tests: the module
checks `Eq`-typed definitions with comparable carriers by evaluating
their two sides. Carriers with functions or types inside are skipped,
with a comment in the emitted module. `--gpu` also adds tests for a
definition whose type is written directly as `Eq` over tiles and whose
left side is an entry applied to closed inputs. These tests run that
entry on the device. An entry without such a proof has no GPU test.

**`NAME.json`** (`--json`, or `-o`). The document is
`{"tile-lang":1,"instances":[...]}`, with a `kernels` member when the
program has entries. An instance is a definition of the program whose
type is data. These are the encodings of the tile-lang types:

| Type | Encoding |
|---|---|
| `Nat` | A number |
| `U32` | A number from 0 to 4294967295 |
| `Flag` | `true` or `false` |
| `Tile R C A` | `{"rows": R, "cols": C, "data": [...]}`, with the R times C cells in row-major order |

The `kernels` member has one object for each entry: its name, the
binding, shape and element of each parameter and of the result, the
workgroup size 64, and the dispatch size (R times C divided by 64,
rounded up).

**Proofs.** Functions, types and `Eq` proofs are not instances, so they
have no JSON value. In the ES module, a type erases to `null` and an
`Eq` proof to `REFL`. A WGSL entry cannot hold an `Eq` value.

## 8. Host and target

Host: TinyCC 0.9.28rc (mob@0fb54300) on AArch64 Darwin. The repository
does not pin a TinyCC commit. Target: WebGPU. The GPU check uses Deno
2.9.3 with `--unstable-webgpu`.

These facts from `probe/CAPABILITY.md` and from the slices set the
design:

- `langc eval` takes arguments only for `Nat` and `Flag` entries. Thus
  each test of a `U32` value or a tile is an `Eq` definition on closed
  values.
- `U32` has no compare, no division and no conversion to `Nat`.
- A WebGPU shader stage has 8 storage buffers by default. Thus an entry
  has at most 7 parameters.
- Each entry numbers its bindings from 0, so a binding is at most 7 for
  each count of entries. This is below the default device limit of 1000
  (`docs/STATUS.md`, L1 is fixed).

The checker refuses an axiom (`REFUSE_AXIOM`), so each `Eq` proof is a
checked term. There is no axiom report. `make check` compares each
output with its golden and runs each ES module in Node. `make gpu-check`
runs each GPU test on a GPU.

## 9. Open items

- O1. GPU access for the tests. RESOLVED 2026-10-10: Deno gets a GPU
  adapter outside the sandbox. The GPU tests run in `make gpu-check`,
  outside `make check`.
- O2. Offline WGSL validation without a GPU (naga-cli, a new tool), or
  Deno on a GPU only. Default: Deno on a GPU only. No new tool.
- O3. Rank 2 only in M1. General rank (a shape as a list of `Nat`) is
  later.
- O4. RULED 2026-10-10: the elements are `U32` and `Flag`, with no `F32`.
  Thus FlashAttention (softmax: exp, max and division) is not in M1.
- O5. Repository and remote. RESOLVED 2026-10-11:
  `MavenRain/tile-lang`.
- O6. The checker normalizes closed `Nat` terms in tile types, and it
  can tell the domain from a program. RESOLVED in the kit (K2) and in T1
  (`REFUSE_BASIS`).
- O7. `reduce` needs an associative `op` (and a commutative `op` for a
  parallel form). M1 trusts the user `op`. `examples/tile-laws.lang`
  proves `u32Add` and `u32Mul` associative on closed values only.

The GPU limit L2 in `docs/STATUS.md` needs a change to the host kit.

## 10. Milestones

| Milestone | Content |
|---|---|
| M0 | Host probe (`probe/CAPABILITY.md`); the core types construct and check; refusal list; examples and tests |
| M1 | The 12 generators and the refusal of the kit basis (T1); the laws as `Eq` proofs (T2); fused kernels and GPU tests (T3); the documents (T4) |

M1: COMPLETE 2026-10-11. No later milestone is planned. A new milestone
needs a new ruling.
