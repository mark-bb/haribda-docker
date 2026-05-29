#!/bin/bash
#
# FUNCTION: Common constants & functions
#

###########
# Constants
###########

CONFIG_LIST_FILE=/setup/configs.txt
INSTALL_SCRIPTS_DIR=/setup/install.d
STARTUP_SCRIPTS_DIR=/setup/startup.d
SHUTDOWN_SCRIPTS_DIR=/setup/shutdown.d
# --env-file variables are not accessible for the startup.service
ENV_FILES_DIR=/setup/utils.d
if [ -d "${ENV_FILES_DIR?}" ]; then
  TEMP_FILE="$(mktemp)"
  find "${ENV_FILES_DIR?}" -type f | sort | while IFS= read -r script; do
    cat "${script?}" | tee -a "${TEMP_FILE?}"
  done
  . "${TEMP_FILE?}"
  rm -f "${TEMP_FILE?}"
fi

if command -v apt-get &>/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  PACKAGE_INSTALL="apt-get -y --no-install-recommends install"
  PACKAGE_MAKECACHE="apt-get update"
  PACKAGE_CLEAN="apt-get clean"
elif command -v dnf &>/dev/null; then
  PACKAGE_INSTALL="dnf -y install"
  PACKAGE_MAKECACHE="dnf makecache"
  PACKAGE_CLEAN="dnf clean all"
elif command -v yum &>/dev/null; then
  PACKAGE_INSTALL="yum -y install"
  PACKAGE_MAKECACHE="yum makecache"
  PACKAGE_CLEAN="yum clean all"
elif command -v zypper &>/dev/null; then
  PACKAGE_INSTALL="zypper install -y --no-recommends"
  PACKAGE_MAKECACHE="zypper refresh"
  PACKAGE_CLEAN="zypper clean --all"
else
  echo "Unknown package manager" >&2
  exit 1
fi
