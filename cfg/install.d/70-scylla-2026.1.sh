#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/../utils.sh"

if [ "${PKGMGR3?}" = "apt" ]; then
        mkdir -p /etc/apt/keyrings
        gpg --homedir /tmp --no-default-keyring --keyring /tmp/temp.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys c503c686b007f39e
        gpg --homedir /tmp --no-default-keyring --keyring /tmp/temp.gpg --export --armor c503c686b007f39e | gpg --dearmor > /etc/apt/keyrings/scylladb.gpg
        wget -O /etc/apt/sources.list.d/scylla.list --no-check-certificate https://downloads.scylladb.com/deb/debian/scylla-2026.1.list
        PACKAGE_MAKECACHE="${PACKAGE_MAKECACHE?} -o Acquire::https::Verify-Peer=false"
        PACKAGE_INSTALL="${PACKAGE_INSTALL?} -o Acquire::https::Verify-Peer=false"
elif [ "${PKGMGR3?}" = "dnf" -o "${PKGMGR3?}" = "yum" ]; then
        curl -o /etc/yum.repos.d/scylla.repo -L https://downloads.scylladb.com/rpm/centos/scylla-2026.1.repo
else
        echo "Not supported platform" >&2
        exit 1
fi

# Create scylla user & group with fixed IDs
u=$(getent passwd ${SCYLLA_UID?} 2>/dev/null) && userdel -r ${u%%:*}
g=$(getent group  ${SCYLLA_GID?} 2>/dev/null) && groupdel   ${g%%:*}
groupadd -g ${SCYLLA_GID?} scylla
useradd -d /var/lib/scylla -s /usr/sbin/nologin -u ${SCYLLA_UID?} -g scylla scylla

${PACKAGE_MAKECACHE?}
${PACKAGE_INSTALL?} scylla

sed -i \
-e "s/^[# ]*\(cluster_name:\).*/\1 '${CLUSTER_NAME?}' /" \
-e "s/^\(endpoint_snitch:\).*/\1 GossipingPropertyFileSnitch/" \
-e "s/^\(rpc_address:\).*/\1 0.0.0.0/" \
-e "s/^[# ]*\(api_address:\).*/\1 0.0.0.0/" \
/etc/scylla/scylla.yaml

cat <<EOF | tee -a "${CONFIG_LIST_FILE?}"
/etc/scylla
/etc/scylla.d
/var/lib/scylla
EOF

systemctl enable scylla-server
systemctl enable scylla-node-exporter
