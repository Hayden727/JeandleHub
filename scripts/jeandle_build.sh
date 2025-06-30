#!/bin/bash

# --- Script Configuration ---
set -euo  # pipefail

# --- Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Global Variables ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
LLVM_PROJECT_DIR="$PROJECT_ROOT/libs/jeandle-llvm"
LLVM_SOURCE_DIR="$LLVM_PROJECT_DIR/llvm"
JDK_SOURCE_DIR="$PROJECT_ROOT/libs/jeandle-jdk"
BUILD_DIR="$PROJECT_ROOT/build"
LLVM_INSTALL_DIR="$BUILD_DIR/jeandle-llvm-install"

OS_ID=""
PKG_MANAGER_CMD=""
SUDO_CMD=""

# --- Function Definitions ---
log_step() { echo -e "\n${BLUE}>>> Step: $1${NC}\n"; }
log_info() { echo -e "${YELLOW}INFO: $1${NC}"; }
log_success() { echo -e "\n${GREEN}✔ $1${NC}\n"; }
log_error() { echo -e "${RED}ERROR: $1${NC}"; }

# --- 1. Environment Setup Functions ---

# Detect OS and package manager
detect_os_and_pm() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
    else
        log_error "Cannot detect operating system. Unsupported system."
        exit 1
    fi

    case "$OS_ID" in
        ubuntu|debian)
            PKG_MANAGER_CMD="apt-get"
            ;;
        centos|fedora|rhel)
            PKG_MANAGER_CMD="dnf"
            ;;
        *)
            log_error "Unsupported OS: '$OS_ID'. Only Debian/Ubuntu and CentOS/Fedora/RHEL families are supported."
            exit 1
            ;;
    esac

    if [[ $EUID -ne 0 ]]; then
        SUDO_CMD="sudo"
    fi
}

# Install system dependencies
install_system_deps() {
    log_info "Checking and installing system dependencies..."
    detect_os_and_pm

    local deps_debian="build-essential autoconf file cmake ninja-build zip unzip \
                       libasound2-dev libcups2-dev libfontconfig1-dev \
                       libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev"
    local deps_fedora="gcc-c++ make autoconf file cmake ninja-build zip unzip \
                       alsa-lib-devel cups-devel fontconfig-devel libXtst-devel \
                       libXi-devel libXrender-devel libXrandr-devel libXt-devel"

    local packages_to_install=""
    if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ]; then
        packages_to_install=$deps_debian
    else
        packages_to_install=$deps_fedora
    fi

    log_info "Will install the following packages for '$OS_ID': $packages_to_install"
    
    if [ "$PKG_MANAGER_CMD" == "apt-get" ]; then
        $SUDO_CMD $PKG_MANAGER_CMD update
        $SUDO_CMD $PKG_MANAGER_CMD install -y $packages_to_install
    else
        $SUDO_CMD $PKG_MANAGER_CMD install -y $packages_to_install
    fi
    log_info "System dependencies installed successfully."
}

# Set up Boot JDK
setup_boot_jdk() {
    local user_provided_path="${1:-}"
    
    # Prefer user-provided path
    if [ -n "$user_provided_path" ]; then
        if [ -d "$user_provided_path" ] && [ -f "$user_provided_path/bin/javac" ]; then
            log_info "Using user-provided Boot JDK: $user_provided_path"
            BOOT_JDK_PATH="$user_provided_path"
            return
        else
            log_error "User-provided Boot JDK path is invalid: $user_provided_path"
            exit 1
        fi
    fi

    # If not provided by user, find or install it automatically
    log_info "Automatically finding or installing Boot JDK (OpenJDK 21)..."
    # Try to find in standard paths
    local found_jdk
    found_jdk=$(find /usr/lib/jvm -maxdepth 1 -type d -name "java-21-openjdk*" | head -n 1)

    if [ -n "$found_jdk" ] && [ -f "$found_jdk/bin/javac" ]; then
        log_info "Found existing OpenJDK 21 at: $found_jdk"
        BOOT_JDK_PATH="$found_jdk"
        return
    fi
    
    # If not found, install it
    log_info "Existing OpenJDK 21 not found. Proceeding with installation..."
    local jdk_package_name=""
    if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ]; then
        jdk_package_name="openjdk-21-jdk"
    else
        jdk_package_name="java-21-openjdk-devel"
    fi

    if [ "$PKG_MANAGER_CMD" == "apt-get" ]; then
        $SUDO_CMD $PKG_MANAGER_CMD install -y $jdk_package_name
    else
        $SUDO_CMD $PKG_MANAGER_CMD install -y $jdk_package_name
    fi

    # Find again after installation
    found_jdk=$(find /usr/lib/jvm -maxdepth 1 -type d -name "java-21-openjdk*" | head -n 1)
    if [ -n "$found_jdk" ] && [ -f "$found_jdk/bin/javac" ]; then
        log_info "Successfully installed and found Boot JDK at: $found_jdk"
        BOOT_JDK_PATH="$found_jdk"
    else
        log_error "Could not find Boot JDK path after installation. Please check manually and specify the path."
        exit 1
    fi
}

# --- Main Logic ---

# --- Argument Parsing ---
BUILD_TYPE="release"
if [[ "${1:-}" == "debug" ]]; then
    BUILD_TYPE="debug"
    # Use the second argument as Boot JDK path (if it exists)
    USER_BOOT_JDK_PATH="${2:-}"
else
    # If the first argument is not "debug", treat it as the Boot JDK path (if it exists)
    if [[ "${1:-}" != "release" ]]; then
        USER_BOOT_JDK_PATH="${1:-}"
    else
        USER_BOOT_JDK_PATH="${2:-}"
    fi
fi

if [ "$BUILD_TYPE" == "debug" ]; then
    CMAKE_BUILD_TYPE="Debug"
    JDK_DEBUG_LEVEL="slowdebug"
else
    CMAKE_BUILD_TYPE="Release"
    JDK_DEBUG_LEVEL="release"
fi

# --- 1. Environment Setup ---
log_step "Environment Setup and Dependency Installation"
install_system_deps
setup_boot_jdk "$USER_BOOT_JDK_PATH"

log_info "Build type: $BUILD_TYPE"
log_info "Boot JDK Path: $BOOT_JDK_PATH"
log_info "Jeandle LLVM Install Directory: $LLVM_INSTALL_DIR"
log_success "Environment is ready!"

# --- 2. Build jeandle-llvm ---
log_step "Building and installing jeandle-llvm (with Ninja)"
LLVM_BUILD_DIR="$BUILD_DIR/llvm-build"
mkdir -p "$LLVM_BUILD_DIR"
cd "$LLVM_BUILD_DIR"

log_info "Configuring with CMake..."
cmake -G "Ninja" \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
      -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" \
      -DLLVM_BUILD_LLVM_DYLIB=On \
      -DLLVM_DYLIB_COMPONENTS=all \
      "$LLVM_SOURCE_DIR"

log_info "Building and installing with Ninja..."
ninja install
log_success "jeandle-llvm built and installed successfully!"

# --- 3. Build jeandle-jdk ---
log_step "Building jeandle-jdk"
cd "$JDK_SOURCE_DIR"

# Thoroughly clean up any previous JDK build artifacts to ensure a clean slate.
# This is more robust than 'make dist-clean' if the previous state was corrupted.
log_info "Cleaning up previous JDK build artifacts..."
rm -rf build

log_info "Configuring jeandle-jdk..."
bash configure \
      --with-boot-jdk="$BOOT_JDK_PATH" \
      --with-debug-level="$JDK_DEBUG_LEVEL" \
      --with-jeandle-llvm="$LLVM_INSTALL_DIR"

log_info "Compiling JDK images (make images)..."
make images JOBS=$(nproc)

# --- 4. Finalization ---
log_step "Build Complete"

# ======================= CORRECTED PATH FINDING LOGIC =======================
# Find the most recently modified 'images/jdk' directory. This is more robust
# than the previous method and ensures we get the one just built.
JDK_IMAGE_DIR_CANDIDATE=$(find "$JDK_SOURCE_DIR/build" -type d -path "*/images/jdk" -printf "%T@ %p\n" | sort -n | tail -n 1 | cut -d' ' -f2-)
# ============================================================================

if [ -z "$JDK_IMAGE_DIR_CANDIDATE" ]; then
    log_error "Build seems complete, but could not auto-locate the compiled JDK image."
    log_info "Please check the '$JDK_SOURCE_DIR/build' directory manually."
else
    JDK_IMAGE_DIR=$(realpath "$JDK_IMAGE_DIR_CANDIDATE")
    log_success "Jeandle JDK built successfully!"
    log_info "The compiled JDK is located at: ${GREEN}$JDK_IMAGE_DIR${NC}"
    log_info "You can start using it with the following commands:"
    echo -e "${YELLOW}export JAVA_HOME=${JDK_IMAGE_DIR}${NC}"
    echo -e "${YELLOW}export PATH=\$JAVA_HOME/bin:\$PATH${NC}"
    echo -e "${YELLOW}java -version${NC}"
fi