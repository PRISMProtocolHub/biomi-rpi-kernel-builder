# Raspberry Pi Kernel building for arm64
FROM ubuntu:22.04 AS builder

# Set environment for ARM64 build
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_DIR=/build
ARG ARCH=arm64
ARG CROSS_COMPILE=aarch64-linux-gnu-

# Kernel source configuration
ARG KERNEL_BRANCH=rpi-6.1.y
ARG KERNEL_GIT=https://github.com/raspberrypi/linux.git

# Install ARM64-specific build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    bison \
    crossbuild-essential-arm64 \
    flex \
    git \
    libssl-dev \
    make \
    gcc-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR $BUILD_DIR

# Clone ARM64-specific kernel repository
RUN git clone --single-branch --depth 1 --branch $KERNEL_BRANCH $KERNEL_GIT linux/

# Kernel configuration and compilation for ARM64
RUN cd linux && \
    # Generate default ARM64 configuration
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig && \
    # Apply Raspberry Pi-specific KVM guest configuration
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE kvm_guest.config && \
    # Compile kernel image for ARM64
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) Image

# Copy custom configuration
COPY config/kernel-custom.conf linux/kernel/configs/custom.config

# Final compilation with custom config
RUN cd linux && \
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE custom.config && \
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) Image

# Final stage with minimal image
FROM scratch
COPY --from=builder /build/linux/arch/arm64/boot/Image $BUILD_DIR/kernel.img