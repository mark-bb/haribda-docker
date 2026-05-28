#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"
[ -f "${CONFIG_LIST_FILE?}" ] || exit 0

while IFS= read -r obj; do
  if [ -d "${obj?}.ORIG" -a -z "$(ls -A "${obj?}")" ]; then
    cp -a "${obj?}.ORIG"/. "${obj?}"
  elif [ -f "${obj?}.ORIG" -a $(stat -c %s "${obj?}") -eq 0 ]; then
    cp "${obj?}.ORIG" "${obj?}"
  fi
  # Permissions and owners
  chmod $(stat -c %a "${obj?}.ORIG") "${obj?}"
  chown $(stat -c %U "${obj?}.ORIG"):$(stat -c %G "${obj?}.ORIG") "${obj?}"
done < "${CONFIG_LIST_FILE?}"
