# Host capability probe: tcc-webgpu

Date: 2026-10-11. Host tree: `/Users/oobi/Documents/tile-lang` at 90b0b2a,
generated from lang-template with `bin/new-lang.sh tile-lang tcc-webgpu`,
read only. Driver: `build/langc` (built 2026-10-11 with `make check`,
TinyCC 0.9.28rc AArch64 Darwin; Node 23.10.0 runs the modules). The probe
did not stop other work on the machine. Thus each wall time is an upper
bound.

To run the probe again: section 6 gives the two program generators and
the guard command for each step. Sections 1 to 5 and 7 to 10 give each
command. They use the files under `examples/` and `test/`, and the small
programs that each section shows. Each step runs below `probe/guard.py`,
which stops a command above 3500 MB resident memory or above 120 s. The
probe writes only below a new temporary directory (`mktemp -d`). The
largest process in the probe used 62.6 MB (`node`, section 6, 1000
kernels).

The domain is still the kit sample (`domain/domain.lang`). The tile-lang
domain replaces it from slice T1 (`docs/PLAN.md`).

## Questions

Each host must answer these questions. Each answer is one numbered section
below. An answer sets the status of a former in `formers/tcc-webgpu.md`.

| Question | Section | Formers |
|---|---|---|
| Which commands check a file, print a normal form, build and run? | 1 | all |
| Does the host take several files, or must the driver join them? | 2 | all |
| Which recursion does the host accept, and how does it refuse the rest? | 3 | F6, F7 |
| Which `Nat` primitives exist? Does `Nat` have an eliminator? | 4 | F6, F7 |
| How does a result leave the host? | 5 | target |
| What do check and build cost (time and resident memory) at N = 100 and N = 1000? | 6 | all |
| Can a family take a parameter? Can a constructor of such a family appear in a term? | 7 | F4, F12, F15 |
| Can a program project a Sigma? Does the kernel accept Sigma eta? | 8 | F11 |
| How does a program use equality: transport, cong, an index type? | 9 | F12, F13 |
| How does the host report an axiom? | 10 | R2 |

## 1. Commands

| Job | Command | Result |
| --- | --- | --- |
| Check | `langc check PROG` | `examples/u32.lang`: `ok`, exit 0. `test/check/u32-from-nat.lang`: `langc: TYPE_MISMATCH: wrong: expected a term of type U32, found a term of type Nat`, exit 1. |
| Print normal form | `langc eval PROG NAME [ARGS...]` | `eval examples/u32.lang wrapped`: `1u`. `eval examples/tiles.lang eye`: `grid 2 2 1u 0u 0u 1u`. |
| Build | `langc build PROG [-o OUT]` and `langc build PROG [--js OUT.js [--selftest [--gpu]]] [--json OUT.json] [--wgsl OUT.wgsl]` | `build examples/u32.lang`: the JSON document on stdout, exit 0. `build examples/kernels.lang --wgsl k.wgsl --js k.js --selftest --json k.json`: exit 0, three files. |
| Run | `node OUT.js`; on a GPU, `make gpu-check` | `node k.js`: exit 0, no output. |

- `langc eval` passes arguments only to an entry (a first-order `Nat` and
  `Flag` definition, `examples/entries.lang`). `eval examples/u32.lang
  double 7u` (`U32 -> U32`) and `eval examples/kernels.lang ofNat 5` (`Nat
  -> U32`) give `langc: EVAL_ARGS: NAME: the definition is not an entry,
  so it takes no arguments`, exit 2. Thus a `U32` or tile function is
  tested with an `Eq` definition on closed values (section 9).
- `--selftest --gpu` on `examples/kernels.lang` builds, exit 0. `node`
  then throws `Error('selftest: 11 GPU tests and no GPU adapter (run: deno
  run --unstable-webgpu)')`, exit 1. On `examples/tiles.lang` (no WGSL
  entry) the same build runs with exit 0.
- Usage errors, each exit 2 with the usage text: `--gpu` without
  `--selftest` (`langc: USAGE: -: --gpu needs --selftest`); `-o` with
  `--js`; the same file for `--js` and `--json` (`--js and --json need
  distinct output files`). `--wgsl` alone builds, exit 0.
- A refused build writes no file: `build test/emit/wgsl-bounds.lang --wgsl
  r.wgsl --js r.js --json r.json` gives `langc: BOUNDS: outE: an at index
  can leave the 2 x 3 tile (row in [0, 1], column in [1, 3]; WGSL select
  runs both arms of flagIf)`, exit 1, and none of the three files exists.
- Not probed: `make gpu-check`. It needs a GPU adapter, and the sandbox
  has none. The USER runs it outside the sandbox
  (`make -C /Users/oobi/Documents/tile-lang gpu-check`).

## 2. Several files

The host takes one file. `langc check examples/sigma.lang
examples/equality.lang` gives `langc: USAGE: -: too many arguments`, exit
2. The domain is not a second file: `gen/embed.c` embeds
`domain/domain.lang` in the executable at build time (section 7 rebuilds
it). A driver that joins files must put each definition after the
definitions that it uses (section 3).

## 3. Recursion and totality

The host accepts no general recursion. It accepts structural recursion
through `fold` over `Nat`, `List` and each domain family, `unfold` into
`List` with a `Nat` step limit, and the index loops `sumTo n` and `foldTo
n` (`langc check examples/tiles.lang`: `ok`). The refusals, each exit 1:

- `test/check/rec.lang`: `langc: REFUSE_REC: loop: def rec is refused
  (rule R3); use fold or unfold`
- `test/check/self.lang`: `langc: REFUSE_REC: loop: loop is this
  definition or a later one; a definition can use only earlier ones (rule
  R3)`
- `test/check/later.lang`: `langc: REFUSE_REC: early: late is this
  definition or a later one; a definition can use only earlier ones (rule
  R3)`

## 4. Nat

The probe program has one closed definition for each case, and `langc
eval` prints each one.

| Definition | Normal form |
| --- | --- |
| `18446744073709551615` | `18446744073709551615` |
| `natAdd most 1`, `natMul most 2` | `trap` |
| `natSub 3 5` | `0` (truncated) |
| `natDiv 17 5`, `natMod 17 5` | `3`, `2` |
| `natDiv 7 0`, `natMod 7 0` | `trap` |
| `fold (fun (acc : Nat) => natAdd acc 5) 0 5` | `25` |
| `natEq 3 3`, `natLe 5 3` | `1`, `0` (a `Flag`) |
| `7u`, `4294967295u` | `7u`, `4294967295u` |
| `u32Add 4294967295u 1u`, `u32Sub 0u 1u`, `u32Mul 65536u 65536u` | `0u`, `4294967295u`, `0u` |

- A `trap` exits 0 in `langc eval` and writes a stderr note, for example
  `langc: EVAL_OVERFLOW: divZero: a Nat operation overflowed past
  2^64-1`. The note says "overflowed" also for a division by 0. `langc
  build` refuses the same program: `langc: EVAL_OVERFLOW: over: the
  instance value traps (a Nat overflow)`, exit 1.
- The primitive names in `src/front/check.c` are `natAdd`, `natSub`,
  `natMul`, `natDiv`, `natMod`, `natEq`, `natLe`, `u32Add`, `u32Sub`,
  `u32Mul`, `flagIf`, `flagYes`, `flagNo`, `strEq`, `showNat`,
  `tabulate`, `at`, `sumTo` and `foldTo`. `langc check` gives `NAME_UNKNOWN`
  for `u32Eq`, `u32Le`, `u32Div`, `u32Mod`, `u32ToNat`, `natToU32`,
  `natLt`, `flagAnd` and `flagNot`. Thus `U32` has no compare, no
  division and no conversion to or from `Nat`. `examples/kernels.lang`
  maps a `Nat` to a `U32` with `sumTo n (fun k => 1u)`.
- `U32` and `Nat` are different types: `test/check/nat-from-u32.lang`
  gives `langc: TYPE_MISMATCH: wrong: expected a term of type Nat, found a
  term of type U32`. The lexer refuses `test/parse/u32-range.lang`
  (`LEX_U32_RANGE: ... a U32 literal is larger than 2^32 - 1`) and
  `test/parse/nat-range.lang` (`LEX_NAT_RANGE: ... a Nat literal is larger
  than 2^64 - 1`).
- The eliminator is `fold`. A definition recurses on a `Nat` with `fold`.
- The largest values that leave the host: `build --json` writes
  `{"name":"most","type":"Nat","value":18446744073709551615}` and
  `{"name":"u32most","type":"U32","value":4294967295}`. In the ES module
  `document`, `most` is a `bigint` and `u32most` is a `number`.

## 5. How a result leaves the host

`langc build examples/kernels.lang --wgsl k.wgsl --js k.js --selftest
--json k.json` writes three files:

- `k.wgsl`: 189 lines, ASCII only, a header comment, then one
  `@compute @workgroup_size(64)` function for each of the 11 entries. The
  first entry is `copyE: Tile 2 3 U32 -> Tile 2 3 U32`, with
  `@group(0) @binding(0) var<storage, read> copyE_in0: array<u32>;` and
  `@group(0) @binding(1) var<storage, read_write> copyE_out: array<u32>;`.
- `k.json`: the keys `tile-lang`, `instances` (3) and `kernels` (11). The
  first kernel is `{"name":"copyE","params":[{"name":"copyE_in0",
  "binding":0,"rows":2,"cols":3,"elem":"U32"}],"result":{"name":
  "copyE_out","binding":1,"rows":2,"cols":3,"elem":"U32"},"workgroup":64,
  "dispatch":1}`.
- `k.js`: an ES module with the exports `document`, `encode`, `entries`,
  `kernels` and `wgsl`. `encode(document)` gives the same bytes as
  `k.json`. `kernels` holds the 11 entries. `entries` is empty, because
  no definition of `examples/kernels.lang` is a `Nat` and `Flag` entry
  (section 1). `kernels.copyE(null)` rejects with `TypeError: copyE: 1
  inputs expected, got 0`, and `kernels.copyE(null, null)` rejects with
  `TypeError: copyE: input 0 is not a tile`, before any use of the device.

A GPU run is `make gpu-check`: Deno with `--unstable-webgpu` runs each
example built with `--selftest --gpu`. Not probed in T0 (section 1).

## 6. Cost

Two programs, each with N definitions:

- chain: `awk -v n=N 'BEGIN { printf "def d0 : Nat := 1\n"; for (i = 1;
  i < n; i++) printf "def d%d : Nat := natAdd d%d 1\n", i, i-1 }'`. It has
  no WGSL entry, so its WGSL module is the header only.
- kernels: `awk -v n=N 'BEGIN { for (i = 0; i < n; i++) printf "def k%d :
  Tile 1 64 U32 -> Tile 1 64 U32 := fun t => tabulate 1 64 (fun i j =>
  u32Add (at t i j) %du)\n", i, i }'`. It has N WGSL entries.

Each step ran as `python3 -I probe/guard.py --rss-mb 3500 --timeout 120
-- COMMAND`. The memory is the guard's `peak_child_mb`. Each step exited
0. "Build all" is `--wgsl --js --json` in one command. "Run" is `node
OUT.js` on the `--js` module (no `--selftest`).

| Step | chain, N = 100 | chain, N = 1000 | kernels, N = 100 | kernels, N = 1000 |
| --- | --- | --- | --- | --- |
| Check | 0.028 s, 2.2 MB | 0.027 s, 6.1 MB | 0.027 s, 3.8 MB | 0.049 s, 21.7 MB |
| Build JSON (`-o`) | 0.024 s, 2.3 MB | 0.027 s, 6.8 MB | 0.027 s, 4.5 MB | 0.052 s, 26.6 MB |
| Build JS (`--js`) | 0.027 s, 2.6 MB | 0.023 s, 7.6 MB | 0.025 s, 4.8 MB | 0.069 s, 28.8 MB |
| Build WGSL (`--wgsl`) | 0.027 s, 2.3 MB | 0.025 s, 6.7 MB | 0.024 s, 4.6 MB | 0.053 s, 26.5 MB |
| Build all | 0.024 s, 2.6 MB | 0.028 s, 7.6 MB | 0.027 s, 4.8 MB | 0.072 s, 28.4 MB |
| Run (`node OUT.js`) | 0.050 s, 41.8 MB | 0.137 s, 49.4 MB | 0.052 s, 42.7 MB | 0.074 s, 62.6 MB |

- The kernels program at N = 1000 gives a WGSL module of 411402 bytes
  with 1000 `@compute` functions, a JS module of 895058 bytes and a JSON
  document of 196603 bytes. Two builds of each program give the same
  WGSL bytes (`cmp`).
- The bindings are unique in a module, so at N = 1000 the largest
  binding is 1999 (each kernel has `dispatch` 1 and `workgroup` 64). The
  WebGPU default `maxBindingsPerBindGroup` is 1000, allowing binding
  indices 0 to 999 ([WebGPU specification](https://gpuweb.github.io/gpuweb/#dom-gpusupportedlimits-maxbindingsperbindgroup)).
  Thus kernels `k500` to `k999` exceed the default device limit. This
  probe measures compilation and module loading only, not GPU execution.
- `make gpu-check` covers `examples/*.lang`, so it does not test this
  generated program. The generated program has no `Eq` definition;
  even with `--selftest --gpu`, its module has no GPU case and exits 0
  in `node` without requesting an adapter. To test the large binding in
  T3, append this definition to the generated program:

  ```
  def highBinding : Eq (Tile 1 64 U32)
    (k999 (tabulate 1 64 (fun i j => 0u)))
    (tabulate 1 64 (fun i j => 999u)) := refl
  ```

  Then build with `langc build PROG --js OUT.js --selftest --gpu` and run
  `deno run --unstable-webgpu OUT.js`, each below the guard. This case
  reaches the GPU path for `k999`, whose bindings are 1998 and 1999;
  they require `maxBindingsPerBindGroup` of at least 2000. The current
  selftest requests a device with default limits (`adapter.requestDevice()`),
  so this is a refusal probe. Not probed in T0: the GPU refusal itself.

## 7. Parametric families

A program cannot declare a family: `test/check/data.lang` gives `langc:
REFUSE_DATA: Coin: a program cannot declare a family (rule R1); only
domain/domain.lang can`, exit 1. The sample domain has `family Lot (size :
Nat) := makeLot (lotPrice : Nat)`, and `langc eval examples/inventory.lang
lotCost` prints `250` (`def lot : Lot 3 := makeLot 3 250`).

A domain family can take a `Type 0` parameter. The probe copied `src`,
`gen`, `domain` and `Makefile` to the temporary directory, added `family
Box (A : Type 0) := box (unbox : A)` to the copy of `domain/domain.lang`,
and ran `make build/langc` (exit 0). With that driver, the program `def b
: Box Nat := box Nat 3`, `def v : Nat := unbox b`, `def w : Box U32 :=
box U32 7u` checks (`ok`). `langc build` writes `{"name":"b","type":"Box
Nat","value":{"unbox":3}}`, `v` as `3` and `w` as `{"unbox":7}`. The
constructor takes the parameter as its first argument. The tile-lang tree
did not change.

`Tile R C A` is a host primitive, not a family. Its cell type `A` is
`U32` or `Flag` only: `test/check/tile-elem.lang` gives `langc:
TILE_ELEM: bad: a Tile element must be U32 or Flag, found Nat`, exit 1.

## 8. Sigma projection and eta

`witness` and `payload` check (`langc check examples/sigma.lang`: `ok`).
The kernel accepts Sigma eta. Both programs below check (`ok`):

- closed: `def s : Sigma (n : Nat) (Eq Nat n 1) := pack 1 refl` and `def
  etaClosed : Eq (Sigma (n : Nat) (Eq Nat n 1)) (pack (witness s)
  (payload s)) s := refl`;
- open: `def etaOpen : (s : Sigma (n : Nat) (Eq Nat n 1)) -> Eq (Sigma (n
  : Nat) (Eq Nat n 1)) (pack (witness s) (payload s)) s := fun (s : Sigma
  (n : Nat) (Eq Nat n 1)) => refl`.

A Sigma pattern does not parse: `fun ((n, p) : Sigma (n : Nat) (Eq Nat n
1)) => n` gives `langc: LEX_CHAR: -: ...: unexpected byte 0x2c`, exit 1.
The forms are `pack`, `witness` and `payload` only.

## 9. Equality

A program writes `Eq A x y` and proves it with `refl`, `symm`, `trans`,
`transport` and `cong`. `langc build examples/equality.lang --js eq.js
--selftest` and `node eq.js` exit 0. `Eq A` takes each type `A`, also
`U32`, `Flag` and `Tile R C A`. This program builds with `--js --selftest
--gpu` and its module runs in `node` with exit 0 (no entry, thus no GPU
test):

```
def t1 : Tile 1 2 U32 := tabulate 1 2 (fun i j => 3u)
def t2 : Tile 1 2 U32 := tabulate 1 2 (fun i j => u32Add 1u 2u)
def same : Eq (Tile 1 2 U32) t1 t2 := refl
def moved : (P : (t : Tile 1 2 U32) -> Type 0) -> (u : P t1) -> P t2 :=
  fun (P : (t : Tile 1 2 U32) -> Type 0) (u : P t1) => transport P same u
def cell : Eq U32 (at t1 0 1) (at t2 0 1) := cong (fun (t : Tile 1 2 U32) => at t 0 1) same
def flagEq : Eq Flag (natLe 1 2) flagYes := refl
```

A false equality fails: `def bad : Eq U32 (u32Add 1u 1u) 3u := refl`
gives `langc: TYPE_REFL: bad: refl cannot prove the equality: the left
side normalizes to 2u, the right side normalizes to 3u`, exit 1. With
`--selftest`, an `Eq`-typed definition becomes a runtime guest test only
when its carrier is comparable data, with no function or type inside.
For example, `def identity : Nat -> Nat := fun n => n` and `def functionEq
: Eq (Nat -> Nat) identity identity := refl` check and build, but the
module contains `// selftest skips 'functionEq': its carrier has a
function or a type inside`. Equality at `Type 0` is also skipped. These
proofs are checked by the C checker; they are not runtime comparisons.

With `--gpu`, a test also becomes a GPU case when its written type is
directly `Eq (Tile R C A) ... ...` and its written left side directly
applies a WGSL entry to closed inputs (tiles or `U32` scalars). An alias
for the equality type, or a left side naming an already computed result,
does not produce a GPU case. A module with no GPU case exits 0 without
requesting an adapter (sections 1 and 6).

## 10. Axiom detection

No command lists axioms, because the checker refuses each axiom (rule R2).
For `test/check/axiom.lang`, `langc check` gives `langc: REFUSE_AXIOM:
magic: an axiom has no proof (rule R2)`, exit 1. For a file with no
axiom, `langc check examples/sigma.lang` prints `ok`, exit 0. Thus each
file that checks has no axiom.

## Consequences for M0

1. The tile-lang driver gives one file to each command, and puts each
   definition after the definitions that it uses (sections 2 and 3).
2. Each loop in a tile-lang program is `sumTo`, `foldTo`, `fold` or
   `unfold`. The kernel operations of the design (copy, map, gemm,
   reduce, view, kernel) are definitions over `tabulate`, `at`, `sumTo`
   and `foldTo` (section 3).
3. Tile cells are `U32` or `Flag` (section 7, ruling R3). `U32` has no
   compare, no division and no conversion to `Nat` (section 4). T1 uses
   `u32Add`, `u32Sub`, `u32Mul`, `flagIf` and `Nat` index terms, or asks
   the USER for a kit primitive.
4. A runtime guest test is an `Eq`-typed definition on closed values with
   a comparable data carrier, built with `--selftest` (section 9). A GPU
   test also needs the written shape described there and `--gpu`.
   `langc eval` cannot pass a `U32` or a tile argument (section 1).
   Run the resulting module with Deno on a GPU to compare it with the C
   values. `make gpu-check` does this for the checked-in examples
   (section 5), but a generated program needs its own case and run.
5. T1 can declare a family with a `Type 0` parameter in
   `domain/domain.lang`. Its constructor takes the parameter as the first
   argument (section 7).
6. The bindings of one WGSL module are unique. Each parameter and each
   result of each entry uses one binding number (section 6). The default
   device limit requires each binding index to be below 1000. T3 must
   exercise a high-binding entry on a GPU with an explicit guest case,
   as shown in section 6.
