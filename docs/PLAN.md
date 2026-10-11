# tile-lang plan

## 1. Rulings

- The language uses only the base types and operations of the design in
  `design/DESIGN.md`. The type formers of lang-template stay. A program
  cannot add a type former.
- Host: TinyCC. Target: WebGPU.
- Route: lang-template gets a generic host kit `hosts/tcc-webgpu`, a fork of
  the `hosts/tcc-js` kit with a WGSL writer. The kit has no tile-lang
  content. tile-lang is then made with
  `bin/new-lang.sh tile-lang tcc-webgpu`.
- Name: tile-lang. The TVM project TileLang has the same name. This is a
  known collision. The compiler binary is `build/langc`.
- Elements: a tile element is a `U32` (arithmetic modulo 2^32) or a `Flag`
  (for masks). There is no `F32` in M1. Each GEMM and each reduce order gives
  the same bits, so the GPU result is equal to the C evaluator result. Thus
  there is no softmax, and FlashAttention is not in M1.
- Output: `NAME.wgsl` (compute shaders), `NAME.js` (an ES module that runs
  the kernels in a browser or in Deno without change) and `NAME.json`
  (bindings, shapes, dispatch sizes and entry order; any WebGPU host can
  load it).
- Tests: unit and integration tests are in the guest language. A host
  runner that loads and runs guest test files is permitted. Do not add a
  node, Python or shell harness.

## 2. Host kit

The host kit is `hosts/tcc-webgpu` in lang-template (slices K0 to K4, done).
It adds the `U32` and `Tile R C A` primitives and a WGSL writer to the
`hosts/tcc-js` front end. `docs/host/README.md` gives the verbs, the
primitives and the limits.

## 3. Domain (slices T, `domain/domain.lang`)

One def for each generator of the design, written on the kit basis:

- `copy t = t` and
  `map f t = tabulate r c (fun i j => f (at t i j))`.
- The pointwise structure of the function space: `fill r c x` (a constant
  tile; also the design allocation that is "initially constant"), `tadd`,
  `tsub` and `tmul`.
- `gemm a b = tabulate m n (fun i j => sumTo k (fun l => u32Mul (at a i l) (at b l j)))`.
  Accumulate form: `gemmAcc c a b = tadd c (gemm a b)`.
- `reduce op e t`: a `Tile 1 1` that folds `op` over all of the shape. The
  design requires `op` to be associative, and commutative for the parallel
  form. M1 does not prove this for a user op (O7).
- `view r0 c0 rs cs m' n' t = tabulate m' n' (fun i j => at t (r0 + rs*i) (c0 + cs*j))`:
  an affine embedding. The transpose `tr` is the other affine embedding of
  rank 2.
- `kernel g1 g2 f`: the product over the block grid. Block (i / t1, j / t2)
  gives the element at (i mod t1, j mod t2). The def uses the kit
  operations `natDiv` and `natMod` on indices only.
- Refusals: a user program cannot call the kit basis (`tabulate`, `at`,
  `sumTo`, `foldTo`) or the Nat operations on elements. Only
  `domain/domain.lang` can.
- Laws as guest Eq proofs on closed tiles, by normalization: the functor
  laws for `map`, `view` composition, `gemm` bilinearity and associativity,
  and `kernel` composition. For each symbolic (open-term) law, record
  PLANNED or HOST-LIMIT.

## 4. Slices and gates

- T0: `bin/new-lang.sh tile-lang tcc-webgpu`, `design/DESIGN.md` (the
  design without change) and this plan. Open: fill `probe/CAPABILITY.md`.
- T1: the domain generators and the refusals of the kit basis in user
  programs. Guest tests for each generator.
- T2: the laws as Eq proofs (section 3).
- T3: kernels. Elementwise, reduce, GEMM, blocked GEMM through the kernel
  grid, and the attention core without softmax (Q K^T V). Each kernel builds
  to WGSL. The GPU tests agree with the C evaluator.
- T4: `SPEC.md`, `docs/STATUS.md` (FlashAttention is out by the element
  ruling), `docs/VALIDATION.md` and `README.md`. Final gate.
- Gate: `make check`. The GPU tests need a GPU adapter, so they run outside
  the sandbox: `make gpu-check` (Deno with `--unstable-webgpu`).

## 5. Open items

- O2: offline WGSL validation without a GPU (naga-cli, a new tool) or only
  Deno on the GPU. Default: Deno only. Ask before an install.
- O3: rank 2 only in M1. General rank (a shape as a list of Nat) is later.
- O4: no `F32` (element ruling). FlashAttention (softmax: exp, max, div) is
  not in M1.
- O7: `reduce` needs an associative op. M1 trusts the user op. An Eq proof
  for each op is a possible T2 addition.
