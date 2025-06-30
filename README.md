# JeandleHub

JeandleHub provides a unified and automated build environment for the [Jeandle](https://github.com/jeandle) project. It is designed to streamline the compilation of Jeandle's two core components: `jeandle-llvm` and `jeandle-jdk`.

This repository uses Git submodules to manage the source code and includes a powerful build script that automates the entire process. The script leverages [Ninja](https://ninja-build.org/) for a significantly faster `jeandle-llvm` build and handles all inter-project dependencies seamlessly.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Step 1: Clone the Repository](#step-1-clone-the-repository)
  - [Step 2: Run the Build Script](#step-2-run-the-build-script)
- [The Build Process Explained](#the-build-process-explained)
- [Build Artifacts](#build-artifacts)

## Prerequisites

Before you begin, please ensure your system has the following software installed.

1.  **Core Build Tools**: `git`, `cmake`, and `ninja`.
    - On **Ubuntu/Debian**:
      ```bash
      sudo apt-get update
      sudo apt-get install git cmake ninja-build
      ```
    - On **Fedora/CentOS/RHEL**:
      ```bash
      sudo dnf install git cmake ninja-build
      ```

2.  **A Boot JDK**: To compile `jeandle-jdk`, you need a pre-existing Java Development Kit. The version of the Boot JDK should typically be the same as (or newer than) the version of the JDK you intend to build. For a build based on OpenJDK 21, you'll need an OpenJDK 21 JDK.
    - On **Ubuntu/Debian**:
      ```bash
      sudo apt-get install openjdk-21-jdk
      ```
    - On **Fedora/CentOS/RHEL**:
      ```bash
      sudo dnf install java-21-openjdk-devel
      ```
    After installation, you will need to know its installation path (e.g., `/usr/lib/jvm/java-21-openjdk-amd64`), as this will be passed as an argument to the build script.

## Getting Started

Follow these two simple steps to build the entire Jeandle project.

### Step 1: Clone the Repository

First, clone this repository. Since `jeandle-llvm` and `jeandle-jdk` are included as Git submodules, you must ensure they are cloned as well.

**Recommended Method:** Use the `--recursive` flag during the initial clone.

```bash
git clone --recursive https://github.com/Hayden727/JeandleHub.git
cd JeandleHub
```

**Alternative Method:** If you have already cloned the repository without the submodules, you can initialize them with the following commands:

```bash
git clone https://github.com/your-username/JeandleHub.git
cd JeandleHub
git submodule update --init --recursive
```

### Step 2: Run the Build Script

The automated build script `build_jeandle.sh` is located in the `scripts/` directory.

The script accepts two arguments:
1.  **Build Type**: `release` (default) or `debug`.
2.  **Boot JDK Path**: The absolute path to the Boot JDK you installed in the [Prerequisites](#prerequisites) step.

**To build the `release` version (recommended for production/general use):**

Replace `/path/to/your/boot-jdk` with the actual path on your system.

```bash
# First, make the script executable
chmod +x scripts/build_jeandle.sh

# Run the build (example using a common OpenJDK 21 path on Ubuntu)
./scripts/build_jeandle.sh release /usr/lib/jvm/java-21-openjdk-amd64
```

**To build the `debug` version:**

If you need to debug the compiler or the runtime, change the first argument to `debug`. This will configure both `jeandle-llvm` and `jeandle-jdk` with debug symbols.

```bash
./scripts/build_jeandle.sh debug /usr/lib/jvm/java-21-openjdk-amd64
```

> **Note**: Compiling LLVM and a full JDK is a resource-intensive process that can take a significant amount of time and disk space. Please be patient.

## The Build Process Explained

The `scripts/build_jeandle.sh` script automates the following sequence:

1.  **Environment Check**: Verifies that all required tools (`cmake`, `ninja`, etc.) are installed and that the source code and Boot JDK paths are valid.
2.  **Build `jeandle-llvm`**:
    - Creates a build directory inside `JeandleHub/build/`.
    - Configures the project using CMake with the **Ninja** generator for maximum parallelism and speed.
    - Compiles and installs `jeandle-llvm` into a local directory (`JeandleHub/build/jeandle-llvm-install/`).
3.  **Build `jeandle-jdk`**:
    - Navigates to the `libs/jeandle-jdk` source directory.
    - Runs the `configure` script, pointing to the just-built `jeandle-llvm` installation via the `--with-jeandle-llvm` flag.
    - Executes `make images` to produce the final, usable JDK image.

## Build Artifacts

Upon successful completion, the script will print the absolute path to the compiled Jeandle JDK image.

The final artifact will be located in a path similar to this:
`.../JeandleHub/libs/jeandle-jdk/build/linux-x86_64-server-release/images/jdk/`

You can start using your custom-built Jeandle JDK by setting the `JAVA_HOME` environment variable:

```bash
# Replace this path with the actual output from the build script
export JAVA_HOME=/path/to/your/JeandleHub/libs/jeandle-jdk/build/linux-x86_64-server-release/images/jdk
export PATH=$JAVA_HOME/bin:$PATH

# Verify the new JDK is active
java -version
```