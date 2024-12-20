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

# To build modules, uncomment
# && make -C linux -j$(nproc) modules \
# && make -C linux modules_install INSTALL_MOD_PATH=$BUILD_DIR/modules_output \
# && tar -czf $BUILD_DIR/modules.tar.gz -C $BUILD_DIR/modules_output/lib/modules . \

# Customize guest image
COPY config/kernel-custom.conf linux/kernel/configs/custom.config
RUN make -C linux defconfig kvm_guest.config \
    && cat linux/kernel/configs/custom.config >> linux/.config \
    && make -C linux olddefconfig \
    && make -C linux -j$(nproc) Image \
    && make -C linux -j$(nproc) modules \
    && make -C linux modules_install INSTALL_MOD_PATH=modules_output \
    && tar -czf modules.tar.gz -C modules_output/lib/modules . \
    && mv linux/arch/arm64/boot/Image kernel.img \
    && rm -rf linux
