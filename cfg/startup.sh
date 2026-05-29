#!/bin/bash
#
# FUNCTION: Called at the boot time
#

set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

"${DIR?}/configs_restore.sh"

# Run all startup scripts
find "${STARTUP_SCRIPTS_DIR?}" -type f -print0 | sort -z | xargs -I {} -0 /bin/bash -c '[ -x "{}" ] && "{}"'
