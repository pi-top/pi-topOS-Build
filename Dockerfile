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

COPY * .

RUN set -x && export ANSIBLE_FORCE_COLOR=true && export TERM=xterm-color

RUN echo "==> Installing run dependencies..."  && \
    apt-get update && \
    apt-get install -y ${DEPENDENCIES} && \
    rm -rf /var/lib/apt/lists/*

RUN echo "==> Running mount_raspios playbook..."  && \
    ansible-playbook mount_raspios.yml

RUN echo "==> Running create_pi_top_os_image playbook..."  && \
    ansible-playbook create_pi_top_os_image.yml

RUN echo "==> Running mount_pi_top_os playbook..."  && \
    ansible-playbook mount_pi_top_os.yml

RUN echo "==> Running install_pi_top_os playbook..."  && \
    ansible-playbook \
      --extra-vars "repo_name=${REPO_NAME} distro_name=${DISTRO_NAME} build_number=${BUILD_NUMBER} build_commit=${BUILD_COMMIT}" \
      install_pi_top_os.yml

RUN echo "==> Running finalise_pi_top_image playbook..."  && \
    ansible-playbook finalise_pi_top_image.yml

RUN echo "==> Running create_debtree_graph playbook..."  && \
    ansible-playbook create_debtree_graph.yml
