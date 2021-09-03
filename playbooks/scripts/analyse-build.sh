#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

set -x

ARTIFACTS_PREFIX="${1}"
ARTIFACTS_PATH="${2:-/tmp/artifacts}"

echo "Getting list of installed pi-top packages..."
installed_pi_top_packages=($(aptitude search "?origin (pi-top) ?installed" -F %p))

generate_package_list() {
  packages_to_use=()
  for p in ${installed_pi_top_packages[@]}; do
    echo "${p}"
    deps=($(apt-cache depends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances ${p} | tail -n +2 | awk '{print $2}' | sort -u))
    for d in ${deps[@]}; do
      d="${d//</}"
      d="${d//>/}"

      echo -e "\t${d}...\c"
      if ! echo ${installed_pi_top_packages[@]} | grep -q -w "${d}"; then
        if ! echo ${packages_to_use[@]} | grep -q -w "${d}"; then
          packages_to_use+=("${d}")
          echo "✔️"
          continue
        fi
      fi
      echo
    done
  done
}

time generate_package_list

append_to_file() {
  text="${1}"
  file="${2}"

  echo "${text}" | sudo tee -a "${file}"
}

update_debtree_file() {
  header="${1}"
  conf_file="${2}"

  append_to_file "" "${conf_file}"
  append_to_file "${header}" "${conf_file}"
  append_to_file "$(printf '%s\n' "${packages_to_use[@]}")" "${conf_file}"
}

if [ ! -d "${ARTIFACTS_PATH}" ]; then
  mkdir "${ARTIFACTS_PATH}"
else
  rm "${ARTIFACTS_PATH}"/*
fi

# Remove previous package list
prefix_text="# remove non pi-top packages from graphs:"
sudo sed -i "/${prefix_text}\$/,\$d" /etc/debtree/skiplist
# Apply new package list
update_debtree_file "${prefix_text}" /etc/debtree/skiplist

debtree --show-installed pt-os | dot -T png >"${ARTIFACTS_PATH}/${ARTIFACTS_PREFIX}-deps-os-pt.png"

tree --charset=ascii /etc/systemd/system >"${ARTIFACTS_PATH}/${ARTIFACTS_PREFIX}-systemd-tree.txt"

exit 0
