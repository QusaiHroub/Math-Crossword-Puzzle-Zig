pub const lNode = struct {
  x: i32,
  y: i32,
  ctr: usize = 0,
  prev: i32 = -1,
  isV: bool,
  dir: bool,
  isMid: bool,
  vector: [3]i32 = [_]i32 {0, 0, 0},
};

pub const Node = struct {
  x: usize,
  y: usize,
  isV: bool,
};