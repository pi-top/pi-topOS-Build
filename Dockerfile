FROM pad92/ansible-alpine:latest

# Build parameters
ARG REPO_NAME=pi-top-os
ARG DISTRO_NAME=sirius
ARG BUILD_NUMBER=0
ARG BUILD_COMMIT=unknown
ARG RECREATE_PI_TOP_OS_IMAGE=true

ENV DEPENDENCIES \
  unzip \
  zerofree

RUN set -x && \
    \
    echo "==> Installing run dependencies..."  && \
    apk add --no-cache ${DEPENDENCIES} && \
    \
    echo "==> Cleaning up..."  && \
    rm -rf /var/cache/apk/* && \
    \
    echo "==> Running playbook..."  && \
    sudo \
      ANSIBLE_FORCE_COLOR=true \
      TERM=xterm-color \
      ansible-playbook \
      --extra-vars repo_name="${REPO_NAME}" \
      --extra-vars distro_name="${DISTRO_NAME}" \
      --extra-vars build_number="${BUILD_NUMBER}" \
      --extra-vars build_commit="${BUILD_COMMIT}" \
      --extra-vars recreate_pi_top_os_image="${RECREATE_PI_TOP_OS_IMAGE}" \
      --inventory inventory/chroots \
      -vv \
      full_pi-top-os_build.yml
