const std = @import("std");
const Io = std.Io;

const client = @import("client");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var args = init.minimal.args.iterate();
    if (!args.skip()) {
        unreachable;
    }

    const peer = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 8083);
    const stream = try peer.connect(io, .{ .mode = .stream });
    defer stream.close(io);

    var buf: [1024]u8 = undefined;
    var writer = stream.writer(io, &buf);
    const out = &writer.interface;

    const cmd = args.next() orelse unreachable;
    var body: [3][]const u8 = .{ "dummy", "", "" };
    var nstr: usize = 2;
    if (std.mem.eql(u8, cmd, "get")) {
        const raw_key = args.next() orelse @panic("usage: get 'key'");
        const key: Key = try .new(raw_key);
        nstr = 2;
        body[0] = "get";
        body[1] = key.val;
    } else if (std.mem.eql(u8, cmd, "set")) {
        std.debug.print("set xxx", .{});
    } else {
        @panic("unsupported command");
    }

    try out.print("{d:0>4}", .{nstr});
    for (body) |item| {
        if (std.mem.eql(u8, item, "")) break;
        try out.print("{d:0>4}{s}", .{ item.len, item });
    }

    try out.flush();
}

// nstr | len | str1 | len | str2 | ...
//   4B    4B           4B
const Body = struct { len: u32, str: []const u8 };
const Data = struct {
    nstr: u32,
    body: []Body,
};

const Key = struct {
    val: []const u8,

    fn new(val: []const u8) !Key {
        if (val.len == 0) {
            return error.InvalidVal;
        }
        return .{
            .val = val,
        };
    }
};
