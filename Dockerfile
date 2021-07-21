FROM debian:unstable-slim as export

# Build information
ENV REPO_NAME=pi-top-os
ENV DISTRO_NAME=sirius
ENV BUILD_NUMBER=0
ENV BUILD_COMMIT=unknown

ENV RPI_OS_ZIP_DIR

ENV DEPENDENCIES \
  ansible \
  qemu-user-static \
  unzip \
  zerofree

ENV ANSIBLE_FORCE_COLOR true
ENV TERM xterm-color

WORKDIR /run
COPY . /run

RUN echo "==> Installing run dependencies..."  && \
    apt-get update && \
    apt-get install -y ${DEPENDENCIES} && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT /run/scripts/entrypoint.sh
