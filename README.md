# tile-lang

tile-lang is a small typed language for tile programs on the GPU. Its core
types and operations come from one denotational design
(`design/DESIGN.md`): a tile is a function from a finite index shape to its
elements. The compiler is written in C and builds with TinyCC. It compiles a
program to a WGSL module, an ES module that runs the kernels with WebGPU, and
a JSON manifest.

tile-lang comes from [lang-template](https://github.com/MavenRain/lang-template)
with the tcc-webgpu host kit. `docs/PLAN.md` gives the rulings, the design
choices and the slices.

- `SPEC.md`: the specification. Fill each section.
- `design/DESIGN.md`: the domain design. It is the only source of the core
  types and the core operations.
- `formers/FORMERS.md`: the type formers. `formers/tcc-webgpu.md` gives their
  status on the tcc-webgpu host.
- `probe/CAPABILITY.md`: the host probe.
- `docs/STATUS.md` and `docs/VALIDATION.md`: the status and the gate results.
- `docs/host/README.md`: how to build and test the host kit, and how to
  replace the sample domain in `domain/`.
