#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

echo "==> Running mount_raspios playbook..."
ansible-playbook playbooks/mount_raspios.yml

echo "==> Running create_pi_top_os_image playbook..."
ansible-playbook playbooks/create_pi_top_os_image.yml

echo "==> Running mount_pi_top_os playbook..."
ansible-playbook playbooks/mount_pi_top_os.yml

echo "==> Running install_pi_top_os playbook..."
ansible-playbook playbooks/ --extra-vars "\
    repo_name=${REPO_NAME}" \
  distro_name=${DISTRO_NAME} \
  build_number=${BUILD_NUMBER} \
  build_commit=${BUILD_COMMIT}"\
  " \
  install_pi_top_os.yml

echo "==> Running finalise_pi_top_image playbook..."
ansible-playbook playbooks/finalise_pi_top_image.yml

echo "==> Running analyse_build playbook..."
ansible-playbook playbooks/analyse_build.yml
