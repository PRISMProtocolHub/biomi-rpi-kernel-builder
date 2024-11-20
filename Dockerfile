# Raspberry Pi Kernel building to /build/kernel.img
FROM ubuntu:latest
ARG DEBIAN_FRONTEND="noninteractive"
ARG BUILD_DIR=/build

# Kernel source
ARG KERNEL_BRANCH=rpi-6.1.y
ARG KERNEL_GIT=https://github.com/raspberrypi/linux.git

# Install kernel build dependencies
RUN apt-get update && apt install -y \
    bc \
    bison \
    crossbuild-essential-arm64 \
    flex \
    git \
    libssl-dev \
    linux-image-generic \
    make \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/locale/*

# Clone the RPI kernel repo
RUN git clone --single-branch --branch $KERNEL_BRANCH $KERNEL_GIT $BUILD_DIR/linux/

# Kernel compile options
ARG ARCH=arm64
ARG CROSS_COMPILE=aarch64-linux-gnu-

WORKDIR $BUILD_DIR

# Compile default VM guest image
RUN make -C $BUILD_DIR/linux defconfig kvm_guest.config \
 && make -C $BUILD_DIR/linux -j$(nproc) Image

# Customize guest image
COPY config/kernel-custom.conf $BUILD_DIR/linux/kernel/configs/custom.config
RUN make -C $BUILD_DIR/linux custom.config \
 && make -C $BUILD_DIR/linux -j$(nproc) Image \
 && mv $BUILD_DIR/linux/arch/arm64/boot/Image $BUILD_DIR/kernel.img \
    && rm -rf $BUILD_DIR/linux