const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const Cell = @import("./cell.zig");
const Lib = @import("./lib.zig");
const LNode = Lib.lNode;
const Node = Lib.Node;
const Queue = std.TailQueue(LNode);
const RndGen = std.rand.DefaultPrng;

pub fn GameBoard() type {
  return struct {
    const Self = @This();
    adjMatrix: ArrayList(ArrayList(Cell.Cell)),
    visited: ArrayList(bool),
    adjList: ArrayList(ArrayList(usize)),
    nodeList: ArrayList(Node),
    height: usize,
    width: usize,
    allocator: Allocator,

    pub fn init (allocator: Allocator, height: usize, width: usize, per: f64) !Self {
      var gameBoard = Self{
        .adjMatrix = ArrayList(ArrayList(Cell.Cell)).init(allocator),
        .visited = ArrayList(bool).init(allocator),
        .adjList = ArrayList(ArrayList(usize)).init(allocator),
        .nodeList = ArrayList(Node).init(allocator),
        .height = height,
        .width = width,
        .allocator = allocator
      };
      
      return try gameBoard.init_board(0, 0, false, per);
    }

    fn init_adj_matrix (self: *Self) !void {
      var adjMatrix = &self.adjMatrix;
      const height = self.height;
      const width = self.width;
      var i: usize = 0;
      adjMatrix.deinit();
    
      while(i < height) : (i += 1) {
        try adjMatrix.append(ArrayList(Cell.Cell).init(self.allocator));
        var j: usize = 0;

        while (j < width) : (j += 1) {
          try adjMatrix.items[i].append(Cell.Cell{.cellType = Cell.ECell.block});
        }
      }
    }

    fn init_adj_list(self: *Self) void {
      var adjList = &self.adjList;
      adjList.deinit();
    }

    fn init_node_list(self: *Self) void {
      var nodeList = &self.nodeList;
      nodeList.deinit();
    }

    fn init_board(self: *Self, startX: usize, startY: usize, isVerticale: bool, per: f64) !Self {
      const min_count = @floatToInt(i32, (@intToFloat(f64, self.height * self.width) / 5) * (per / 10.0));
      const adjList = &self.adjList;

      while (adjList.items.len < min_count) {
        try self.init_puzzle(startX, startY, isVerticale);
      }

      return self.*;
    }

    fn init_puzzle(self: *Self, startX: usize, startY: usize, isVerticale: bool) !void {
      try self.init_adj_matrix();
      self.init_adj_list();
      self.init_node_list();
      var adjList = &self.adjList;
      var nodeList = &self.nodeList;
      var adjMatrix = &self.adjMatrix;
      var n = ArrayList(LNode).init(self.allocator);
      var rnd = RndGen.init(0);
      var queue: Queue = Queue{};
      queue.append(&Queue.Node{.data = LNode{
        .isV = isVerticale,
        .y = @intCast(i32, startY),
        .x = @intCast(i32, startX),
        .isMid = false,
        .dir = true
      }});

      while(queue.len != 0) {
        var front = queue.popFirst().?.data;
        const isOk = self.check(
          @intCast(usize, front.x),
          @intCast(usize, front.y),
          front.isV
        );

        if (!isOk) {
          continue;
        }

        try adjList.append(ArrayList(usize).init(self.allocator));

        if (front.prev != -1) {
          const end = adjList.items.len - 1;
          const prev = @intCast(usize, front.prev);
          try adjList.items[prev].append(end);
          try adjList.items[end].append(prev);
        }

        var node = Node{
          .isV = front.isV,
          .x = @intCast(usize, front.x),
          .y = @intCast(usize, front.y)
        };
        try nodeList.append(node);

        if (front.isV) {
          const newY = front.y;
          const end = newY + 5;
          var k: usize = @intCast(usize, newY);
          const x = @intCast(usize, front.x);

          while (k < end) : (k += 1) {
            if (k == newY + 1) {
              adjMatrix.items[k].items[x] = Cell.Cell{.cellType = Cell.ECell.operation, .value = "X"};
            } else if (k == newY + 3) {
              adjMatrix.items[k].items[x] = Cell.Cell{
                .cellType = Cell.ECell.operation,
                .value = "=",
                .status = false
              };
            } else {
              adjMatrix.items[k].items[x] = Cell.Cell{.cellType = Cell.ECell.numeric, .value = ""};
              front.vector[front.ctr] = @intCast(i32, k);
              front.ctr += 1;
            }
          }
        } else {
          const newX = front.x;
          const end = newX + 5;
          var k: usize = @intCast(usize, newX);
          const y = @intCast(usize, front.y);

          while (k < end) : (k += 1) {
            if (k == newX + 1) {
              adjMatrix.items[y].items[k] = Cell.Cell{.cellType = Cell.ECell.operation, .value = "X"};
            } else if (k == newX + 3) {
              adjMatrix.items[y].items[k] = Cell.Cell{
                .cellType = Cell.ECell.operation,
                .value = "=", 
                .status = false
              };
            } else {
              adjMatrix.items[y].items[k] = Cell.Cell{.cellType = Cell.ECell.numeric, .value = ""};
              front.vector[front.ctr] = @intCast(i32, k);
              front.ctr += 1;
            }
          }
        }

        var k: usize = 0;

        while(k < 3) : (k += 1) {
          const isMid = rnd.random().boolean();
          const dir = rnd.random().boolean();
          var lNode = LNode{
            .x = if (front.isV) front.x else front.vector[k],
            .y = if (front.isV) front.vector[k] else front.y,
            .isV = !front.isV,
            .isMid = isMid,
            .dir = dir,
            .prev = @intCast(i32, adjList.items.len - 1),
          };

          try n.append(lNode);
          try n.append(lNode);
          try n.append(lNode);
          n.items[1].isMid = !n.items[1].isMid;
          n.items[2].isV = !n.items[2].isV;

          for (n.items) |*vNode| {
            if (vNode.*.isMid) {
              if (vNode.*.isV) {
                vNode.*.y -= 2;
              } else {
                vNode.*.x -= 2;
              }

              vNode.*.dir = true;
            } else if (!vNode.*.dir) {
              if (vNode.*.isV) {
                vNode.*.y -= 4;
              } else {
                vNode.*.x -= 4;
              }

              vNode.*.dir = true;
            }

            if (vNode.*.y >= 0 and vNode.*.x >= 0) {
              queue.append(&Queue.Node{.data = vNode.*});
            }
          }
        }
      }
    }

    fn check(self: *const Self, x: usize, y: usize, isV: bool) bool {
      const adjMatrix = &self.adjMatrix;
      const height = self.height;
      const width = self.width;
      
      if (isV) {
        if (y + 5 > height) {
          return false;
        }

        if (y + 6 < height and adjMatrix.items[y + 5].items[x].cellType != Cell.ECell.block) {
          return false;
        }
        
        if (y > 0 and adjMatrix.items[y - 1].items[x].cellType != Cell.ECell.block) {
          return false;
        }

        if (
          adjMatrix.items[y + 3].items[x].cellType != Cell.ECell.block
          or adjMatrix.items[y + 1].items[x].cellType != Cell.ECell.block
        ) {
          return false;
        }

        if (adjMatrix.items[y + 1].items[x].cellType == Cell.ECell.operation) {
          const oCell = adjMatrix.items[y + 1].items[x];

          if (mem.eql(u8, oCell.value, "=")) {
            return false;
          }
        }
      } else {
        if (x + 5 > width) {
          return false;
        }

        if (x + 6 < width and adjMatrix.items[y].items[x + 5].cellType != Cell.ECell.block) {
          return false;
        }

        if (x > 0 and adjMatrix.items[y].items[x - 1].cellType != Cell.ECell.block) {
          return false;
        }

        if (
          adjMatrix.items[y].items[x + 3].cellType != Cell.ECell.block
          or adjMatrix.items[y].items[x + 1].cellType != Cell.ECell.block
        ) {
          return false;
        }

        if (adjMatrix.items[y].items[x + 1].cellType == Cell.ECell.operation) {
          const oCell = adjMatrix.items[y].items[x + 1];

          if (mem.eql(u8, oCell.value, "=")) {
            return false;
          }
        }
      }

      return true;
    }
  };
}
