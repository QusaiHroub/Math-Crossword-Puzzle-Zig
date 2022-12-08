const std = @import("std");
const Allocator = std.mem.Allocator;
var length: u8 = 0;

pub const ECell = enum { block, value, operation, numeric, core };

pub fn updateLength(len: u8) void {
    if (length < len) {
        length = len;
    }
}

pub const Cell = struct {
    cellType: ECell = .core,
    value: []const u8 = "",
    status: bool = true,
    gvalue: []const u8 = "",

    pub fn toString(self: *const Cell, allocator: Allocator) ![]u8 {
        return switch (self.cellType) {
            ECell.block => blockCell(allocator),
            ECell.operation => operationCell(self, allocator),
            ECell.numeric => numericCell(self, allocator),
            else => blockCell(allocator),
        };
    }

    fn blockCell(allocator: Allocator) ![]u8 {
        const result = try allocator.alloc(u8, length);
        var i: u8 = 0;

        while (i < length) : (i += 1) {
            result[i] = ' ';
        }

        return result;
    }

    fn operationCell(self: *const Cell, allocator: Allocator) ![]u8 {
        const result = try allocator.alloc(u8, length);
        const n: u8 = length - @intCast(u8, self.value.len);
        const m: u8 = n / 2;
        const end: u8 = m + (n & 1);
        var i: u8 = 0;

        while (i < m) : (i += 1) {
            result[i] = ' ';
        }

        for (self.value) |char| {
            result[i] = char;
            i += 1;
        }

        while (i < end) : (i += 1) {
            result[i] = ' ';
        }

        return result;
    }

    fn getNumericCellValueLen(self: *const Cell) u8 {
        if (self.status) {
            return @intCast(u8, self.gvalue.len);
        }

        return @intCast(u8, self.value.len);
    }

    fn numericCell(self: *const Cell, allocator: Allocator) ![]u8 {
        const result = try allocator.alloc(u8, length);
        const n: u8 = length - getNumericCellValueLen(self);
        const m: u8 = n / 2;
        const end: u8 = m + (n & 1);
        var i: u8 = 0;

        while (i < m) : (i += 1) {
            result[i] = ' ';
        }

        if (self.status) {
            for (self.gvalue) |char| {
                result[i] = char;
                i += 1;
            }
        } else {
            for (self.value) |char| {
                result[i] = char;
                i += 1;
            }
        }

        while (i < end) : (i += 1) {
            result[i] = ' ';
        }

        return result;
    }
};

test "Test cell ... 1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var test2 = Cell{ .cellType = ECell.numeric, .gvalue = "test" };
    updateLength(4);
    const string = try test2.toString(allocator);
    try std.testing.expect(std.mem.eql(u8, string, "test"));
}

test "Test cell ... 2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var test2 = Cell{ .cellType = ECell.numeric, .gvalue = "test" };
    updateLength(7);
    test2.gvalue = "test2";
    const string = try test2.toString(allocator);
    try std.testing.expect(std.mem.eql(u8, string, " test2 "));
}