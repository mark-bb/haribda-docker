#!/bin/bash
#
# FUNCTION: Called at the boot time
#

set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

# Just for test
echo "$(date): system shutdown" | tee -a /.shutdown.service.log
# Run all shutdown scripts
find "${SHUTDOWN_SCRIPTS_DIR?}" -type f -print0 | sort -z | xargs -I {} -0 /bin/bash -c '[ -x "{}" ] && "{}"'
