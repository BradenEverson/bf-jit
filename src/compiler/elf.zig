//! ELF File Format stuff

const std = @import("std");

pub const Elf64_Addr = u64;
pub const Elf64_Off = u64;
pub const Elf64_Section = u16;
pub const Elf64_Versym = u16;
pub const Elf64_Byte = u8;
pub const Elf64_Half = u16;
pub const Elf64_Sword = i32;
pub const Elf64_Word = u32;
pub const Elf64_Sxword = i64;
pub const Elf64_Xword = u64;

pub const ElfType = enum(u16) {
    /// File identification
    EI_MAG0 = 0,
    /// File identification
    EI_MAG1 = 1,
    /// File identification
    EI_MAG2 = 2,
    /// File identification
    EI_MAG3 = 3,
    /// File class
    EI_CLASS = 4,
    /// Data encoding
    EI_DATA = 5,
    /// File version
    EI_VERSION = 6,
    /// Operating system/ABI identification
    EI_OSABI = 7,
    /// ABI version
    EI_ABIVERSION = 8,
    /// Start of padding bytes
    EI_PAD = 9,
    /// Size of e_ident[]
    EI_NIDENT = 16,
};

pub const Elf64_Ehdr = struct {
    e_ident: [@intFromEnum(ElfType.EI_NIDENT)]u8,
    e_type: u16,
    e_machine: u16,
    e_version: u32,
    e_entry: Elf64_Addr,
    e_shoff: Elf64_Off,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,

    pub fn default() Elf64_Ehdr {
        return Elf64_Ehdr{};
    }
};

pub const Elf64_Phdr = struct {
    p_type: u32,
    p_flags: u32,
    p_offset: Elf64_Off,
    p_vaddr: Elf64_Addr,
    p_paddr: Elf64_Addr,
    p_filesz: u64,
    p_memsz: u64,
    p_align: u64,
};

pub const Elf64_Shdr = struct {
    sh_name: u32,
    sh_type: u32,
    sh_flags: u64,
    sh_addr: Elf64_Addr,
    sh_offset: Elf64_Off,
    sh_size: u64,
    sh_link: u32,
    sh_info: u32,
    sh_addralign: u64,
    sh_entsize: u64,
};

pub const Elf64_Sym = struct {
    st_name: u32,
    st_info: u8,
    st_other: u8,
    st_shndx: u16,
    st_value: Elf64_Addr,
    st_size: u64,
};

const entry = [_]u8{
    0x7F, 0x45, 0x4C, 0x46,
    0x02, 0x01, 0x01, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x3E, 0x00,
    0x01, 0x00, 0x00, 0x00,
    0x78, 0x00, 0x40, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x40, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x40, 0x00, 0x38, 0x00,
    0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00,
    0x05, 0x00, 0x00, 0x00,
    0x78, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x78, 0x00, 0x40, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,

    // Program len
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,

    0x10, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x10, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
};

/// The exit syscall
const exit = [_]u8{
    0x48, 0xC7, 0xC0, 0x3C,
    0x00, 0x00, 0x00, 0x48,
    0xC7, 0xC7, 0x2A, 0x00,
    0x00, 0x00, 0x0F, 0x05,
};

pub fn wrap_elf(program: []const u8, buf: *std.ArrayList(u8)) !void {
    var header = entry;
    // Program size is the 3rd to last word
    const program_size_idx = header.len - (3 * 8);
    const size: u64 = program.len + exit.len;

    for (0..8) |i| {
        header[program_size_idx + i] = @intCast((size >> @intCast(i * 8)));
    }

    _ = try buf.appendSlice(&header);
    _ = try buf.appendSlice(program);
    _ = try buf.appendSlice(&exit);
}
