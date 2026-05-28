#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/../utils.sh"

${PACKAGE_INSTALL?} openssh-server
