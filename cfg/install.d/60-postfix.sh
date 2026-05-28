#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/../utils.sh"

${PACKAGE_INSTALL?} postfix
${PACKAGE_INSTALL?} mailx
echo "/etc/postfix" | tee -a "${CONFIG_LIST_FILE?}"
systemctl enable postfix
