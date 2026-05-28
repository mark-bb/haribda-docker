#!/bin/bash

set -x
for n in $(seq 3 -1 1); do
  docker exec haribda-0${n?} /bin/bash -c "nodetool drain && systemctl stop haribda-server" &
done
wait
