// langc build --wgsl: one compute shader for each entry of the program
// (an entry maps tiles and U32 values to a tile). A buffer holds the cells
// of a tile in row-major order as u32 values (a Flag cell is 0u or 1u).
// Invocation x of an entry writes the cell x of the result.

// axpyE: U32 -> Tile 4 4 U32 -> Tile 4 4 U32 -> Tile 4 4 U32
@group(0) @binding(0) var<storage, read> axpyE_in0: array<u32>;
@group(0) @binding(1) var<storage, read> axpyE_in1: array<u32>;
@group(0) @binding(2) var<storage, read> axpyE_in2: array<u32>;
@group(0) @binding(3) var<storage, read_write> axpyE_out: array<u32>;

@compute @workgroup_size(64)
fn axpyE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 16u) {
    return;
  }
  let i = idx / 4u;
  let j = idx % 4u;
  axpyE_out[idx] = ((axpyE_in0[0] * axpyE_in1[i * 4u + j]) + axpyE_in2[i * 4u + j]);
}

// dotE: Tile 4 4 U32 -> Tile 4 4 U32 -> Tile 1 1 U32
@group(0) @binding(4) var<storage, read> dotE_in0: array<u32>;
@group(0) @binding(5) var<storage, read> dotE_in1: array<u32>;
@group(0) @binding(6) var<storage, read_write> dotE_out: array<u32>;

@compute @workgroup_size(64)
fn dotE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 1u) {
    return;
  }
  let i = idx / 1u;
  let j = idx % 1u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 16u; l1 = l1 + 1u) {
    l0 = (l0 + (dotE_in0[(l1 / 4u) * 4u + (l1 % 4u)] * dotE_in1[(l1 / 4u) * 4u + (l1 % 4u)]));
  }
  dotE_out[idx] = l0;
}

// prodE: Tile 4 4 U32 -> Tile 1 1 U32
@group(0) @binding(7) var<storage, read> prodE_in0: array<u32>;
@group(0) @binding(8) var<storage, read_write> prodE_out: array<u32>;

@compute @workgroup_size(64)
fn prodE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 1u) {
    return;
  }
  let i = idx / 1u;
  let j = idx % 1u;
  var l0 = 1u;
  for (var l1 = 0u; l1 < 16u; l1 = l1 + 1u) {
    l0 = (l0 * prodE_in0[(l1 / 4u) * 4u + (l1 % 4u)]);
  }
  prodE_out[idx] = l0;
}

// gemmE: Tile 4 4 U32 -> Tile 4 4 U32 -> Tile 4 4 U32
@group(0) @binding(9) var<storage, read> gemmE_in0: array<u32>;
@group(0) @binding(10) var<storage, read> gemmE_in1: array<u32>;
@group(0) @binding(11) var<storage, read_write> gemmE_out: array<u32>;

@compute @workgroup_size(64)
fn gemmE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 16u) {
    return;
  }
  let i = idx / 4u;
  let j = idx % 4u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 4u; l1 = l1 + 1u) {
    l0 = l0 + (gemmE_in0[i * 4u + l1] * gemmE_in1[l1 * 4u + j]);
  }
  gemmE_out[idx] = l0;
}

// blockedE: Tile 4 4 U32 -> Tile 4 4 U32 -> Tile 4 4 U32
@group(0) @binding(12) var<storage, read> blockedE_in0: array<u32>;
@group(0) @binding(13) var<storage, read> blockedE_in1: array<u32>;
@group(0) @binding(14) var<storage, read_write> blockedE_out: array<u32>;

@compute @workgroup_size(64)
fn blockedE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 16u) {
    return;
  }
  let i = idx / 4u;
  let j = idx % 4u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 2u; l1 = l1 + 1u) {
    l0 = l0 + (blockedE_in0[(((i / 2u) * 2u) + (1u * (i % 2u))) * 4u + (0u + (1u * l1))] * blockedE_in1[(0u + (1u * l1)) * 4u + (((j / 2u) * 2u) + (1u * (j % 2u)))]);
  }
  var l2 = 0u;
  for (var l3 = 0u; l3 < 2u; l3 = l3 + 1u) {
    l2 = l2 + (blockedE_in0[(((i / 2u) * 2u) + (1u * (i % 2u))) * 4u + (2u + (1u * l3))] * blockedE_in1[(2u + (1u * l3)) * 4u + (((j / 2u) * 2u) + (1u * (j % 2u)))]);
  }
  blockedE_out[idx] = (l0 + l2);
}

// attnE: Tile 4 2 U32 -> Tile 4 2 U32 -> Tile 4 3 U32 -> Tile 4 3 U32
@group(0) @binding(15) var<storage, read> attnE_in0: array<u32>;
@group(0) @binding(16) var<storage, read> attnE_in1: array<u32>;
@group(0) @binding(17) var<storage, read> attnE_in2: array<u32>;
@group(0) @binding(18) var<storage, read_write> attnE_out: array<u32>;

@compute @workgroup_size(64)
fn attnE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 12u) {
    return;
  }
  let i = idx / 3u;
  let j = idx % 3u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 4u; l1 = l1 + 1u) {
    var l2 = 0u;
    for (var l3 = 0u; l3 < 2u; l3 = l3 + 1u) {
      l2 = l2 + (attnE_in0[i * 2u + l3] * attnE_in1[l1 * 2u + l3]);
    }
    l0 = l0 + (l2 * attnE_in2[l1 * 3u + j]);
  }
  attnE_out[idx] = l0;
}

// linE: Tile 4 2 U32 -> Tile 4 2 U32 -> Tile 4 3 U32 -> Tile 4 3 U32
@group(0) @binding(19) var<storage, read> linE_in0: array<u32>;
@group(0) @binding(20) var<storage, read> linE_in1: array<u32>;
@group(0) @binding(21) var<storage, read> linE_in2: array<u32>;
@group(0) @binding(22) var<storage, read_write> linE_out: array<u32>;

@compute @workgroup_size(64)
fn linE(@builtin(global_invocation_id) id: vec3<u32>) {
  let idx = id.x;
  if (idx >= 12u) {
    return;
  }
  let i = idx / 3u;
  let j = idx % 3u;
  var l0 = 0u;
  for (var l1 = 0u; l1 < 2u; l1 = l1 + 1u) {
    var l2 = 0u;
    for (var l3 = 0u; l3 < 4u; l3 = l3 + 1u) {
      l2 = l2 + (linE_in1[l3 * 2u + l1] * linE_in2[l3 * 3u + j]);
    }
    l0 = l0 + (linE_in0[i * 2u + l1] * l2);
  }
  linE_out[idx] = l0;
}
