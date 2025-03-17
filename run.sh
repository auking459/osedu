#!/bin/bash

set -euo pipefail

#===========================================================
# Constants
#===========================================================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

ROOT_DIR=$(git rev-parse --show-toplevel)
WORK_DIR="${ROOT_DIR}/.work"
TOOLCHAIN_DIR="${WORK_DIR}/toolchains"
# RISCV64_TOOLCHAIN_PATH="${TOOLCHAIN_DIR}/riscv/bin"
# RISCV64_CROSS_TOOLCHAIN="${RISCV64_TOOLCHAIN_PATH}/riscv64-unknown-linux-gnu-"

RISCV32_TOOLCHAIN_PATH="${TOOLCHAIN_DIR}/riscv/bin"
RISCV32_CROSS_TOOLCHAIN="${RISCV32_TOOLCHAIN_PATH}/riscv32-unknown-linux-gnu-"

QEMU_VERSION="9.2.0"
QEMU_DIR="${WORK_DIR}/qemu-${QEMU_VERSION}"
QEMU_BUILD_DIR="${QEMU_DIR}/build"
QEMU_BIN="${QEMU_BUILD_DIR}/qemu-system-riscv32"

RISCV_IMAGES_DIR="${WORK_DIR}/images"

GDB_DIR="${SCRIPT_DIR}/gdb"

OPENSBI_BIN="fw_jump.bin"
EGOS_BIN="hello.bin"

#===========================================================
# Functions
#===========================================================
function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

function prepare_toolchains {
    echo "🚀 Preparing toolchains..."

    UBUNTU_VERSION=$(lsb_release -rs)
    TAG="2025.01.20"
    TOOLCHAIN_URL="https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download"
    FILENAME="riscv64-glibc-ubuntu-${UBUNTU_VERSION}-llvm-nightly-${TAG}-nightly.tar.xz"

    if [ ! -d "${RISCV64_TOOLCHAIN_PATH}" ]; then
        mkdir -p "${TOOLCHAIN_DIR}"
        cd "${TOOLCHAIN_DIR}"
        wget "${TOOLCHAIN_URL}/${TAG}/${FILENAME}"
        tar -xf "${FILENAME}"
        rm "${FILENAME}"
        cd -
    fi

    echo "🎉 Toolchains prepared!"
}

function prepare_toolchains_riscv32 {
    echo "🚀 Preparing toolchains..."

    UBUNTU_VERSION=$(lsb_release -rs)
    TAG="2025.01.20"
    TOOLCHAIN_URL="https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download"
    FILENAME="riscv32-glibc-ubuntu-${UBUNTU_VERSION}-llvm-nightly-${TAG}-nightly.tar.xz"

    if [ ! -d "${RISCV32_TOOLCHAIN_PATH}" ]; then
        mkdir -p "${TOOLCHAIN_DIR}"
        cd "${TOOLCHAIN_DIR}"
        wget "${TOOLCHAIN_URL}/${TAG}/${FILENAME}"
        tar -xf "${FILENAME}"
        rm "${FILENAME}"
        cd -
    fi

    echo "🎉 Toolchains prepared!"
}

function prepare_qemu {
    echo "🚀 Preparing QEMU..."

    if [ ! -d "${QEMU_DIR}" ]; then
        mkdir -p "${QEMU_DIR}"
        cd "${QEMU_DIR}"
        wget "https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz"
        tar -xf "qemu-${QEMU_VERSION}.tar.xz"
        rm "qemu-${QEMU_VERSION}.tar.xz"
        cd -
    fi

    if [ ! -f "${QEMU_BIN}" ]; then
        mkdir -p "${QEMU_BUILD_DIR}"
        cd "${QEMU_BUILD_DIR}"
        "${QEMU_DIR}/qemu-${QEMU_VERSION}/configure" \
            --target-list=riscv64-softmmu,riscv32-softmmu \
            --prefix="${QEMU_DIR}"
        make -j$(nproc)
        cd -
    fi

    "${QEMU_BIN}" --version

    echo "🎉 QEMU prepared!"
}

function prepare_egos {
    echo "🚀 Preparing Egos..."

    REPO="https://github.com/auking459/egos-2000.git"
    BRANCH="main"
    SRC_DIR="${WORK_DIR}/egos-2000"

    if [ ! -d "${SRC_DIR}" ]; then
        git clone -b "${BRANCH}" "${REPO}" "${SRC_DIR}"
    fi

    cd "${SRC_DIR}"

    export CROSS_COMPILE="${RISCV32_CROSS_TOOLCHAIN}"

    make

    cp -f ./${EGOS_BIN} "${RISCV_IMAGES_DIR}/"

    cd -

    echo "🎉 Egos-2000 prepared!"
}

function setup {
    echo "🚀 Setting up workspace..."

    mkdir -p "${WORK_DIR}"
    mkdir -p "${RISCV_IMAGES_DIR}"

    prepare_toolchains
    prepare_qemu
    prepare_egos

    echo "🎉 Workspace setup complete!"
}

function run_qemu {
    echo "🚀 Running QEMU..."

    ARGS=(
        -machine virt
        -nographic
        -smp 1
        -bios "${RISCV_IMAGES_DIR}/${EGOS_BIN}"
    )

    "${QEMU_BIN}" "${ARGS[@]}" "${@}"
}

function run_gdb {
    echo "🚀 Running GDB..."

    export GDB_WORK_DIR="${WORK_DIR}"
    gdb-multiarch -x "${GDB_DIR}/.gdbinit" --cd="${GDB_DIR}"
}

#===========================================================
# Script begins here
#===========================================================
TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
