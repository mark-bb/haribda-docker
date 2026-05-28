#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"
[ -f "${CONFIG_LIST_FILE?}" ] || exit 0

while IFS= read -r obj; do
  cp -a "${obj?}" "${obj?}.ORIG"
done < "${CONFIG_LIST_FILE?}"
