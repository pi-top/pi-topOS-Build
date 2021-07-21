FROM debian:unstable-slim as export

# Build parameters
ARG REPO_NAME=pi-top-os
ARG DISTRO_NAME=sirius
ARG BUILD_NUMBER=0
ARG BUILD_COMMIT=unknown

ENV DEPENDENCIES \
  ansible \
  qemu-user-static \
  unzip \
  zerofree

ENV ANSIBLE_FORCE_COLOR true
ENV TERM xterm-color

WORKDIR /run
COPY * /run

RUN echo "==> Installing run dependencies..."  && \
    apt-get update && \
    apt-get install -y ${DEPENDENCIES} && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT /run/scripts/entrypoint.sh
