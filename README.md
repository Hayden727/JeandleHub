# JeandleHub

Welcome to JeandleHub, the central repository for tools, scripts, and resources designed to support the [Jeandle](https://github.com/jeandle) project. This hub aims to streamline development, testing, and management of the entire Jeandle ecosystem.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Available Tools](#available-tools)
  - [Automated Build System (`scripts/build_jeandle.sh`)](#automated-build-system-scriptsbuild_jeandlesh)
    - [Prerequisites for Building](#prerequisites-for-building)
    - [How to Run the Build](#how-to-run-the-build)
    - [Build Artifacts](#build-artifacts)
- [Contributing](#contributing)

## Overview

JeandleHub is envisioned as a toolbox for Jeandle developers. While it will grow to include scripts for testing, analysis, and more, its primary feature today is a powerful, automated build system.

**Current Features:**
*   **Automated Build System:** A robust script to compile `jeandle-llvm` and `jeandle-jdk` from source with a single command, using Ninja for accelerated builds.

*(More tools are planned for the future!)*

## Getting Started

To get started with JeandleHub, first clone the repository. This project uses Git submodules to manage the source code for `jeandle-llvm` and `jeandle-jdk`, so you must ensure they are cloned as well.

**Recommended Method:** Use the `--recursive` flag during the initial clone.
```bash
git clone --recursive https://github.com/Hayden727/JeandleHub.git
cd JeandleHub
```

**Alternative Method:** If you have already cloned the repository, initialize the submodules with this command:
```bash
git submodule update --init --recursive
```

## Available Tools

This section details the scripts and tools available within the `scripts/` directory.

### Automated Build System (`scripts/build_jeandle.sh`)

This is the primary tool for compiling the entire Jeandle stack from source. It automates the process of building `jeandle-llvm` and then using it to build `jeandle-jdk`.

#### Prerequisites for Building

Before running the build script, please ensure your system has the following software installed:

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

2.  **A Boot JDK**: A pre-existing Java Development Kit is required to compile `jeandle-jdk`. Its version should generally match the target JDK version. For a build based on OpenJDK 21, you'll need an OpenJDK 21 JDK.
    - On **Ubuntu/Debian**:
      ```bash
      sudo apt-get install openjdk-21-jdk
      ```
    After installation, you will need its installation path (e.g., `/usr/lib/jvm/java-21-openjdk-amd64`).

#### How to Run the Build

The script `scripts/build_jeandle.sh` accepts two arguments: the build type (`release` or `debug`) and the path to your Boot JDK.

1.  **Make the script executable:**
    ```bash
    chmod +x scripts/build_jeandle.sh
    ```

2.  **Run the build:**
    *   **For a `release` build (recommended):**
        Replace `/path/to/your/boot-jdk` with the actual path.
        ```bash
        ./scripts/build_jeandle.sh release /usr/lib/jvm/java-21-openjdk-amd64
        ```

    *   **For a `debug` build:**
        ```bash
        ./scripts/build_jeandle.sh debug /usr/lib/jvm/java-21-openjdk-amd64
        ```

> **Note**: This is a resource-intensive process that can take a significant amount of time and disk space. Please be patient.

#### Build Artifacts

Upon successful completion, the script will print the absolute path to the compiled Jeandle JDK image. The artifact will be located in a path similar to:
`.../JeandleHub/libs/jeandle-jdk/build/linux-x86_64-server-release/images/jdk/`

You can start using it by setting the `JAVA_HOME` environment variable:
```bash
# Replace this path with the actual output from the build script
export JAVA_HOME=/path/to/your/JeandleHub/libs/jeandle-jdk/build/linux-x86_64-server-release/images/jdk
export PATH=$JAVA_HOME/bin:$PATH

# Verify the new JDK is active
java -version
```

## Contributing

Contributions are welcome! JeandleHub is an evolving project. If you have ideas for new scripts, improvements to existing ones, or other resources that would benefit Jeandle developers, feel free to open an issue or submit a pull request.