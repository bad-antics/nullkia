# NullKia Docker Image
# docker build -t nullkia .
# docker run -it --privileged -v /dev/bus/usb:/dev/bus/usb nullkia

FROM ubuntu:22.04

LABEL maintainer="bad-antics"
LABEL description="NullKia Mobile Security Framework"
LABEL version="2.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV NULLKIA_HOME=/opt/nullkia

# Install dependencies
RUN apt-get update && apt-get install -y \
    adb \
    fastboot \
    android-sdk-platform-tools \
    git \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    libusb-1.0-0 \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Create nullkia user
RUN useradd -m -s /bin/bash nullkia && \
    usermod -aG plugdev nullkia

# Copy source
COPY . /opt/nullkia/
WORKDIR /opt/nullkia

# Install
RUN chmod +x install.sh && \
    mkdir -p /home/nullkia/.local/bin && \
    cp -r . /home/nullkia/.nullkia && \
    chown -R nullkia:nullkia /home/nullkia

# Setup udev rules (for privileged mode)
COPY installer/51-nullkia.rules /etc/udev/rules.d/

USER nullkia
WORKDIR /home/nullkia

# Add to PATH
ENV PATH="/home/nullkia/.local/bin:${PATH}"

ENTRYPOINT ["/bin/bash"]
CMD ["--login"]
