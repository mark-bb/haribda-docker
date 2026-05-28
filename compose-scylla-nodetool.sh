#!/bin/bash

set -x
for n in $(seq 1 3); do
  docker exec haribda-0${n?} /bin/bash -c "nodetool status"
done
