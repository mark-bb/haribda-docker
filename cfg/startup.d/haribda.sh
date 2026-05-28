#!/bin/bash
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/../utils.sh"

[ -f /etc/scylla.d/io_properties.yaml ] || scylla_dev_mode_setup --developer-mode 1

IP="$(hostname -i | cut -d' ' -f1)"
sed -i \
-e "s/^[# ]*\(cluster_name:\).*/\1 '${CLUSTER_NAME?}'/" \
-e "s/^\( *- seeds:\).*/\1 \"${SEEDS?}\"/" \
-e "s/^\(listen_address:\).*/\1 ${IP?}/" \
-e "s/^[# ]*\(broadcast_rpc_address:\).*/\1 ${IP?}/" \
/etc/scylla/scylla.yaml

sed -i \
-e "s/^[# ]*\(dc=\).*/\1${DC?}/" \
-e "s/^[# ]*\(rack=\).*/\1${RACK?}/" \
/etc/scylla/cassandra-rackdc.properties
