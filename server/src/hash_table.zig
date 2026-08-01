const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub fn HashTable(comptime T: type) type {
    return struct {
        const Self = @This();

        const bucket_size: usize = 8;

        const Entry = struct {
            key: []const u8,
            value: T,
            next: ?*Entry = null,
        };

        buckets: [bucket_size]?*Entry,

        pub fn init() Self {
            return Self{ .buckets = @splat(null) };
        }

        fn hash_index(key: []const u8) u64 {
            const hash = std.hash.Wyhash.hash(0, key);
            return hash % bucket_size;
        }

        pub fn put(self: *Self, key: []const u8, value: T) void {
            const index = hash_index(key);

            var current = self.buckets[index];

            while (current) |entry| {
                if (std.mem.eql(u8, key, entry.key)) {
                    entry.value = value;
                    return;
                }
                current = entry.next;
            }

            var entry = Entry{ .key = key, .value = value, .next = self.buckets[index] };

            self.buckets[index] = &entry;
        }

        pub fn get(self: Self, key: []const u8) ?T {
            const index = hash_index(key);

            var current = self.buckets[index];

            while (current) |entry| {
                if (std.mem.eql(u8, key, entry.key)) {
                    return entry.value;
                }
                current = entry.next;
            }

            return null;
        }

        pub fn debug_print(self: Self) void {
            for (0..bucket_size) |i| {
                var bucket = self.buckets[i];
                while (bucket) |entry| {
                    std.debug.print("key={s} value={s}\n", .{ entry.key, entry.value });
                    bucket = entry.next;
                }
            }
        }
    };
}

test "init" {
    _ = HashTable(u8).init();
}

test "put key/value" {
    var htable = HashTable([]const u8).init();
    htable.put("key", "value");
    htable.debug_print();
    try testing.expectEqual("value", htable.get("key"));
}
