// langc build --wgsl: one compute shader for each entry of the program
// (an entry maps tiles and U32 values to a tile). A buffer holds the cells
// of a tile in row-major order as u32 values (a Flag cell is 0u or 1u).
// Invocation x of an entry writes the cell x of the result.

// copyE: Tile 2 3 U32 -> Tile 2 3 U32
@group(0) @binding(0) var<storage, read> copyE_in0: array<u32>;
@group(0) @binding(1) var<storage, read_write> copyE_out: array<u32>;

@compute @workgroup_size(64)
fn copyE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 6u) {
    return;
  }
  let i = idx / 3u;
  let j = idx % 3u;
  copyE_out[idx] = copyE_in0[i * 3u + j];
}

// mapE: Tile 2 3 U32 -> Tile 2 3 U32
@group(0) @binding(2) var<storage, read> mapE_in0: array<u32>;
@group(0) @binding(3) var<storage, read_write> mapE_out: array<u32>;

@compute @workgroup_size(64)
fn mapE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 6u) {
    return;
  }
  let i = idx / 3u;
  let j = idx % 3u;
  mapE_out[idx] = (mapE_in0[i * 3u + j] * 3u);
}

// addE: Tile 2 3 U32 -> Tile 2 3 U32 -> Tile 2 3 U32
@group(0) @binding(4) var<storage, read> addE_in0: array<u32>;
@group(0) @binding(5) var<storage, read> addE_in1: array<u32>;
@group(0) @binding(6) var<storage, read_write> addE_out: array<u32>;

@compute @workgroup_size(64)
fn addE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 6u) {
    return;
  }
  let i = idx / 3u;
  let j = idx % 3u;
  addE_out[idx] = (addE_in0[i * 3u + j] + addE_in1[i * 3u + j]);
}

// scaleE: U32 -> Tile 2 3 U32 -> Tile 2 3 U32
@group(0) @binding(7) var<storage, read> scaleE_in0: array<u32>;
@group(0) @binding(8) var<storage, read> scaleE_in1: array<u32>;
@group(0) @binding(9) var<storage, read_write> scaleE_out: array<u32>;

@compute @workgroup_size(64)
fn scaleE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 6u) {
    return;
  }
  let i = idx / 3u;
  let j = idx % 3u;
  scaleE_out[idx] = (scaleE_in0[0] * scaleE_in1[i * 3u + j]);
}

// gemmE: Tile 2 3 U32 -> Tile 3 2 U32 -> Tile 2 2 U32
@group(0) @binding(10) var<storage, read> gemmE_in0: array<u32>;
@group(0) @binding(11) var<storage, read> gemmE_in1: array<u32>;
@group(0) @binding(12) var<storage, read_write> gemmE_out: array<u32>;

@compute @workgroup_size(64)
fn gemmE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 4u) {
    return;
  }
  let i = idx / 2u;
  let j = idx % 2u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 3u; l1 = l1 + 1u) {
    l0 = l0 + (gemmE_in0[i * 3u + l1] * gemmE_in1[l1 * 2u + j]);
  }
  gemmE_out[idx] = l0;
}

// accE: Tile 2 2 U32 -> Tile 2 3 U32 -> Tile 3 2 U32 -> Tile 2 2 U32
@group(0) @binding(13) var<storage, read> accE_in0: array<u32>;
@group(0) @binding(14) var<storage, read> accE_in1: array<u32>;
@group(0) @binding(15) var<storage, read> accE_in2: array<u32>;
@group(0) @binding(16) var<storage, read_write> accE_out: array<u32>;

@compute @workgroup_size(64)
fn accE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 4u) {
    return;
  }
  let i = idx / 2u;
  let j = idx % 2u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 3u; l1 = l1 + 1u) {
    l0 = l0 + (accE_in1[i * 3u + l1] * accE_in2[l1 * 2u + j]);
  }
  accE_out[idx] = (accE_in0[i * 2u + j] + l0);
}

// sumE: Tile 2 3 U32 -> Tile 1 1 U32
@group(0) @binding(17) var<storage, read> sumE_in0: array<u32>;
@group(0) @binding(18) var<storage, read_write> sumE_out: array<u32>;

@compute @workgroup_size(64)
fn sumE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 1u) {
    return;
  }
  let i = idx / 1u;
  let j = idx % 1u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 6u; l1 = l1 + 1u) {
    l0 = (l0 + sumE_in0[(l1 / 3u) * 3u + (l1 % 3u)]);
  }
  sumE_out[idx] = l0;
}

// viewE: Tile 2 3 U32 -> Tile 2 2 U32
@group(0) @binding(19) var<storage, read> viewE_in0: array<u32>;
@group(0) @binding(20) var<storage, read_write> viewE_out: array<u32>;

@compute @workgroup_size(64)
fn viewE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 4u) {
    return;
  }
  let i = idx / 2u;
  let j = idx % 2u;
  viewE_out[idx] = viewE_in0[(0u + (1u * i)) * 3u + (1u + (1u * j))];
}

// trE: Tile 2 3 U32 -> Tile 3 2 U32
@group(0) @binding(21) var<storage, read> trE_in0: array<u32>;
@group(0) @binding(22) var<storage, read_write> trE_out: array<u32>;

@compute @workgroup_size(64)
fn trE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 6u) {
    return;
  }
  let i = idx / 2u;
  let j = idx % 2u;
  trE_out[idx] = trE_in0[j * 3u + i];
}

// blockE: Tile 4 4 U32 -> Tile 4 4 U32
@group(0) @binding(23) var<storage, read> blockE_in0: array<u32>;
@group(0) @binding(24) var<storage, read_write> blockE_out: array<u32>;

@compute @workgroup_size(64)
fn blockE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 16u) {
    return;
  }
  let i = idx / 4u;
  let j = idx % 4u;
  blockE_out[idx] = blockE_in0[(((i / 2u) * 2u) + (1u * (j % 2u))) * 4u + (((j / 2u) * 2u) + (1u * (i % 2u)))];
}

// emptyRowsE: U32 -> Tile 1 1 U32
@group(0) @binding(25) var<storage, read> emptyRowsE_in0: array<u32>;
@group(0) @binding(26) var<storage, read_write> emptyRowsE_out: array<u32>;

@compute @workgroup_size(64)
fn emptyRowsE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 1u) {
    return;
  }
  let i = idx / 1u;
  let j = idx % 1u;
  emptyRowsE_out[idx] = emptyRowsE_in0[0];
}

// emptyColsE: U32 -> Tile 1 1 U32
@group(0) @binding(27) var<storage, read> emptyColsE_in0: array<u32>;
@group(0) @binding(28) var<storage, read_write> emptyColsE_out: array<u32>;

@compute @workgroup_size(64)
fn emptyColsE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 1u) {
    return;
  }
  let i = idx / 1u;
  let j = idx % 1u;
  emptyColsE_out[idx] = emptyColsE_in0[0];
}

// emptyGemmE: U32 -> Tile 2 3 U32
@group(0) @binding(29) var<storage, read> emptyGemmE_in0: array<u32>;
@group(0) @binding(30) var<storage, read_write> emptyGemmE_out: array<u32>;

@compute @workgroup_size(64)
fn emptyGemmE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 6u) {
    return;
  }
  _ = arrayLength(&emptyGemmE_in0);
  let i = idx / 3u;
  let j = idx % 3u;
  emptyGemmE_out[idx] = 0u;
}
