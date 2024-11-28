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
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean
# Clone the RPI kernel repo
RUN git clone --single-branch --branch $KERNEL_BRANCH $KERNEL_GIT $BUILD_DIR/linux/

# Kernel compile options
#ENV ARCH=arm64
#ENV CROSS_COMPILE=aarch64-linux-gnu-

WORKDIR $BUILD_DIR

# Compile default VM guest image
RUN make -C linux defconfig kvm_guest.config \
 && make -C linux -j$(nproc) Image

# Customize guest image
COPY config/kernel-custom.conf linux/kernel/configs/custom.config
RUN make -C linux custom.config \
 && make -C linux -j$(nproc) Image \
 && mv linux/arch/arm64/boot/Image kernel.img \
    && rm -rf linux