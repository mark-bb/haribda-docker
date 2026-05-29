#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/../utils.sh"

if [ "${PKGMGR3?}" = "apt" ]; then
	printf "deb [trusted=yes] https://repos.stsoft.dev/repository/haribda-deb release main\n" | tee /etc/apt/sources.list.d/haribda.list
	PACKAGE_MAKECACHE="${PACKAGE_MAKECACHE?} -o Acquire::https::Verify-Peer=false"
	PACKAGE_INSTALL="${PACKAGE_INSTALL?} -o Acquire::https::Verify-Peer=false"
elif [ "${PKGMGR3?}" = "dnf" -o "${PKGMGR3?}" = "yum" ]; then
	cat <<-EOF | tee /etc/yum.repos.d/haribda-6.2.3.repo
	[haribda-6.2.3]
	name=Haribda 6.2.3
	baseurl=https://repos.stsoft.dev/repository/haribda-rpm/6.2.3
	gpgcheck=0
	enabled=1
	sslverify=0
	EOF
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
# ${PACKAGE_INSTALL?} haribda{-server,-tools,-tools-core,-kernel-conf,-node-exporter,-conf,-python3,-cqlsh}
${PACKAGE_INSTALL?} haribda

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

systemctl enable haribda-server
systemctl enable haribda-node-exporter
