const std = @import("std");
const SPIRV_MAGIC:     u32 = 0x07230203;
const SPIRV_VERSION:   u32 = 0x00010300;
const SPIRV_GENERATOR: u32 = 0x00000000;
const SPIRV_SCHEMA:    u32 = 0x00000000;

const Op = struct {
    const Capability:       u32 = 17;
    const ExtInstImport:    u32 = 11;
    const MemoryModel:      u32 = 14;
    const EntryPoint:       u32 = 15;
    const ExecutionMode:    u32 = 16;
    const TypeVoid:         u32 = 19;
    const TypeFunction:     u32 = 33;
    const TypeFloat:        u32 = 22;
    const TypeVector:       u32 = 23;
    const Constant:         u32 = 43;
    const Function:         u32 = 54;
    const FunctionEnd:      u32 = 56;
    const Return:           u32 = 253;
};

pub const ShaderStage = enum {
    vertex,
    fragment,
};


pub const SpirvBuilder = struct {
    words: std.ArrayList(u32),
    allocator: std.mem.Allocator,
    id_counter: u32,

    pub fn init(allocator: std.mem.Allocator) SpirvBuilder {
        return SpirvBuilder{
            .words = std.ArrayList(u32).init(allocator),
            .allocator = allocator,
            .id_counter = 1,
        };
    }

    pub fn deinit(self: *SpirvBuilder) void {
        self.words.deinit();
    }

    pub fn newId(self: *SpirvBuilder) u32 {
        const id = self.id_counter;
        self.id_counter += 1;
        return id;
    }

    pub fn emit(self: *SpirvBuilder, word: u32) !void {
        try self.words.append(word);
    }

    pub fn emitHeader(self: *SpirvBuilder, bound: u32) !void {
        try self.emit(SPIRV_MAGIC);
        try self.emit(SPIRV_VERSION);
        try self.emit(SPIRV_GENERATOR);
        try self.emit(bound); 
        try self.emit(SPIRV_SCHEMA);
    }

    pub fn emitInstruction(self: *SpirvBuilder, opcode: u32, operands: []const u32) !void {
        const word_count: u32 = @intCast(1 + operands.len);
        try self.emit((word_count << 16) | opcode);
        for (operands) |operand| {
            try self.emit(operand);
        }
    }

    pub fn finalize(self: *SpirvBuilder) []u32 {
        return self.words.items;
    }
};

pub fn buildShader(allocator: std.mem.Allocator, stage: ShaderStage) ![]u32 {
    _ = stage;
    var builder = SpirvBuilder.init(allocator);
    defer builder.deinit();

    const bound: u32 = 16; // placeholder bound, will be dynamic later
    try builder.emitHeader(bound);

    try builder.emitInstruction(Op.Capability, &[_]u32{1});

    try builder.emitInstruction(Op.MemoryModel, &[_]u32{ 0, 1 });

    const void_type_id = builder.newId();
    try builder.emitInstruction(Op.TypeVoid, &[_]u32{void_type_id});

    const func_type_id = builder.newId();
    try builder.emitInstruction(Op.TypeFunction, &[_]u32{ func_type_id, void_type_id });

    const float_type_id = builder.newId();
    try builder.emitInstruction(Op.TypeFloat, &[_]u32{ float_type_id, 32 });

    const vec4_type_id = builder.newId();
    try builder.emitInstruction(Op.TypeVector, &[_]u32{ vec4_type_id, float_type_id, 4 });

    const main_id = builder.newId();
    try builder.emitInstruction(Op.Function, &[_]u32{ void_type_id, main_id, 0, func_type_id });
    try builder.emitInstruction(Op.Return, &[_]u32{});
    try builder.emitInstruction(Op.FunctionEnd, &[_]u32{});
    const bytecode = try allocator.dupe(u32, builder.finalize());
    return bytecode;
}
