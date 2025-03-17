import os
import gdb

# Get current working directory
cwd = os.getcwd()

# Get the directory from the environment variable
gdb_work_dir = os.getenv("GDB_WORK_DIR")

if gdb_work_dir is None:
    raise RuntimeError("GDB_WORK_DIR environment variable is not set")

# Get the directory contains projects
work_dir = os.path.join(gdb_work_dir, "builds")

# ==============================================
# Load symbols
# ==============================================
opensbi_path = os.path.join(
    work_dir, "opensbi/platform/generic/firmware/fw_jump.elf"
)
gdb.execute(f"file {opensbi_path}")

symbol_files = [
    "linux/vmlinux",
]

for symbol_file in symbol_files:
    symbol_path = os.path.join(work_dir, symbol_file)
    gdb.execute(f"add-symbol-file {symbol_path}")

# ==============================================
# Set breakpoints
# ==============================================
gdb.Breakpoint("*0x80000000")
gdb.Breakpoint("*0x80200000")
# gdb.Breakpoint("fw_main")
