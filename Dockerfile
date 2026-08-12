FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        curl \
        ca-certificates \
        bzip2 \
    && rm -rf /var/lib/apt/lists/*

ARG ARM_GCC_VERSION=10.3-2021.10
ARG ARM_GCC_ARCHIVE=gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
ARG ARM_GCC_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
ARG ARM_GCC_MD5=2383e4eb4ea23f248d33adc70dc3227e

WORKDIR /opt

RUN curl -fL --retry 5 --retry-delay 2 \
        -A "Mozilla/5.0" \
        "$ARM_GCC_URL" \
        -o "$ARM_GCC_ARCHIVE" && \
    echo "$ARM_GCC_MD5  $ARM_GCC_ARCHIVE" | md5sum -c - && \
    tar -xjf "$ARM_GCC_ARCHIVE" && \
    rm "$ARM_GCC_ARCHIVE"

ENV PATH="/opt/gcc-arm-none-eabi-${ARM_GCC_VERSION}/bin:${PATH}"

RUN arm-none-eabi-gcc --version && \
    make --version | head -n 1

WORKDIR /workspace

CMD ["bash"]
