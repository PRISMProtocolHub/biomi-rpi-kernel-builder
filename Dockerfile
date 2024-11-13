# Raspberry Pi Kernel building to /build/kernel.img
FROM debian:latest
ARG BUILD_DIR=/build

# Kernel source
ARG KERNEL_BRANCH=rpi-6.1.y
ARG KERNEL_GIT=https://github.com/raspberrypi/linux.git

# Install kernel build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    gcc \
    bison \
    crossbuild-essential-arm64 \
    flex \
    git \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR $BUILD_DIR

# Set kernel build environment variables
ENV ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu-

# Clone and compile kernel
RUN git clone --depth 1 --single-branch --branch $KERNEL_BRANCH $KERNEL_GIT $BUILD_DIR/linux/ \
    && make -C $BUILD_DIR/linux defconfig kvm_guest.config \
    && make -C $BUILD_DIR/linux -j$(nproc) Image

COPY src/conf/custom.conf $BUILD_DIR/linux/kernel/configs/custom.config
RUN make -C $BUILD_DIR/linux custom.config \
    && make -C $BUILD_DIR/linux -j$(nproc) Image \
    && mv $BUILD_DIR/linux/arch/arm64/boot/Image $BUILD_DIR/kernel.img \
    && rm -rf $BUILD_DIR/linux