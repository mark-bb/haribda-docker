#!/bin/bash
#
# FUNCTION: install the software
#

set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

# Processing secrets if any
SECRET_DIR="/run/secrets"
if [ -d "${SECRET_DIR?}" ]; then
  TEMP_FILE="$(mktemp)"
  find "${SECRET_DIR?}" -type f -print0 | sort -z | xargs -0 cat | tee "${TEMP_FILE?}"
  . "${TEMP_FILE?}"
  rm -f "${TEMP_FILE?}"
fi

# Install additional packages if provided
if [ -n "${ADD_PACKAGES}" ]; then
  ${PACKAGE_MAKECACHE?}
  pkgs=/tmp/packages; mkdir "${pkgs?}"; cd "${pkgs?}"
  IFS=' ' read -r -a packages <<< "${ADD_PACKAGES}"
  for x in "${!packages[@]}"; do
    if [ "$(printf "${PACKAGE_INSTALL?}" | cut -c1-3)" = "apt" -a "$(printf "${packages[x]}" | cut -c1-4)" = "http" ]; then
      wget ${packages[x]}
      dpkg -i *.deb
      rm -f *.deb
    else
      ${PACKAGE_INSTALL?} ${packages[x]}
    fi
  done
  cd "${DIR?}" 
  rm -rf "${pkgs?}"
fi

${PACKAGE_MAKECACHE?}
# Install systemd & other useful packages
${PACKAGE_INSTALL?} binutils file gzip tar vim systemd hostname procps curl wget
[ "${PKGMGR3?}" = "apt" ] && ${PACKAGE_INSTALL?} gpg dirmngr gpg-agent

# Run all setup scripts
find "${INSTALL_SCRIPTS_DIR?}" -type f -print0 | sort -z | xargs -I {} -0 /bin/bash -c '[ -x "{}" ] && "{}"'

if [ "$(printf "${PACKAGE_INSTALL?}" | cut -c1-3)" = "zyp" ]; then
  if ! getent passwd mail &>/dev/null; then
    groupadd -g 8 mail
    useradd -d /var/spool/mail -s /usr/sbin/nologin -g mail -u 8 mail
    chown root:mail /var/spool/mail
  fi

  if ! getent passwd bin &>/dev/null; then
    groupadd -g 2 bin
    useradd -d /bin -s /usr/sbin/nologin -g bin -u 2 bin
  fi
fi

${PACKAGE_CLEAN?}

# Save configs
"${DIR?}/configs_save.sh"

# To copy configs & run all startup scripts on system boot
unit=startup
cat <<EOF | tee /etc/systemd/system/${unit?}.service
[Unit]
Description=Copy configs to mounted if needed
Before=basic.target
After=local-fs.target sysinit.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/setup/startup.sh

[Install]
WantedBy=basic.target
EOF
systemctl enable ${unit?}

# Called before the OS shutdown
unit=shutdown
cat <<EOF | tee /etc/systemd/system/${unit?}.service
[Unit]
Description=Cleanup on shutdown if needed
Before=shutdown.target umount.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/setup/shutdown.sh

[Install]
WantedBy=shutdown.target umount.target
EOF
systemctl enable ${unit?}

[ -f /sbin/init ] || ln -s /lib/systemd/systemd /sbin/init
