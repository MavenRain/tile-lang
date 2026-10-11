# tile-lang

tile-lang is a small typed language for tile programs on the GPU. Its core
types and operations come from one denotational design
(`design/DESIGN.md`): a tile is a function from a finite index shape to its
elements. The compiler is written in C and builds with TinyCC. It compiles a
program to a WGSL module, an ES module that runs the kernels with WebGPU, and
a JSON manifest.

A tile is `Tile r c U32`: `r` rows and `c` columns of `U32` cells
(arithmetic modulo 2^32). A program makes and changes tiles with 12
generators: `copy`, `tmap`, `fill`, `tadd`, `tsub`, `tmul`, `gemm`,
`gemmAcc`, `reduce`, `view`, `tr` and `kernel`. A definition with tile
parameters and a tile result is an entry, and each entry becomes one
compute shader. `SPEC.md` gives the language.

tile-lang comes from [lang-template](https://github.com/MavenRain/lang-template)
with the tcc-webgpu host kit. The TVM project TileLang has the same name.
This language is a different project.

## Build

You need TinyCC (`tcc`), a C compiler (`cc`), Node, ripgrep (`rg`) and a
POSIX shell. For the GPU check, you also need Deno and a GPU.

```sh
make build
```

This builds `build/langc`.

## Check

```sh
make check
```

This builds the compiler and runs all tests. `docs/VALIDATION.md` tells
what each gate line checks.

## GPU check

```sh
make gpu-check
```

This runs the GPU tests of each example under Deno with
`--unstable-webgpu`. It needs a GPU adapter, so it is not part of
`make check`.

## Use

```sh
build/langc check examples/fused.lang
build/langc build examples/fused.lang --wgsl fused.wgsl --json fused.json
build/langc build examples/fused.lang --js fused.js --selftest
node fused.js
build/langc build examples/fused.lang --js fused-gpu.js --selftest --gpu
deno run --unstable-webgpu fused-gpu.js
```

`docs/host/README.md` gives all commands and the form of each output.

## Examples

- `examples/tiles.lang`: `Eq` tests for the 12 generators.
- `examples/kernels.lang`: 13 entries over the generators, each with a
  GPU test.
- `examples/fused.lang`: 7 fused entries (axpy, a dot product, GEMM,
  blocked GEMM and the attention core without softmax), with 12 GPU
  tests.
- `examples/tile-laws.lang`: the laws of the design as 35 `Eq` proofs.
- `examples/u32.lang`: the `U32` operations.
- The other examples (`algebra`, `entries`, `equality`, `formers`,
  `functions`, `laws`, `monad`, `sigma`, `text` and `universes`) show the
  type formers of the kit.

## Files

- `SPEC.md`: the specification.
- `design/DESIGN.md`: the domain design. It is the only source of the core
  types and the core operations.
- `domain/domain.lang`: the 12 generators. `domain/README.md` tells how the
  domain works.
- `docs/STATUS.md`: what works, the limits and the open work.
- `docs/VALIDATION.md`: the gate and the test results.
- `docs/PLAN.md`: the rulings and the slices.
- `formers/FORMERS.md`: the type formers. `formers/tcc-webgpu.md` gives their
  status on the tcc-webgpu host.
- `probe/CAPABILITY.md`: the host probe.
- `docs/host/README.md`: the commands, the outputs and the limits of the
  host kit.

## License

MIT or Apache-2.0, at your option (`LICENSE-MIT`, `LICENSE-APACHE`).
