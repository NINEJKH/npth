#!/usr/bin/env bash

readlink_bin="${READLINK_PATH:-readlink}"
if ! "${readlink_bin}" -f test &> /dev/null; then
  __DIR__="$(dirname "$(python -c "import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))" "${0}")")"
else
  __DIR__="$(dirname "$("${readlink_bin}" -f "${0}")")"
fi

# required libs
source "${__DIR__}/.bash/functions.shlib"

set -E
trap 'throw_exception' ERR

while IFS= read -r -d '' -u 9; do
  temp="${REPLY##*targets/}"
  temp="${temp%*/Dockerfile}"

  consolelog "building ${temp}..."
  docker build \
    --pull \
    --build-arg "PACKAGE_NAME=${PACKAGE_NAME}" \
    -t "dotdeb-${PACKAGE_NAME}:${temp}" \
    -f "${REPLY}" \
    "targets/${temp}"

  for file in $(docker run "dotdeb-${PACKAGE_NAME}:${temp}" bash -c 'ls /usr/src/*.deb'); do
    last_docker_id="$(docker ps -l -q)"
    consolelog "* fetching artefact ${file}..."
    docker cp "${last_docker_id}:${file}" "targets/${temp}"
  done

done 9< <( find targets -type f -name Dockerfile -exec printf '%s\0' {} + )
