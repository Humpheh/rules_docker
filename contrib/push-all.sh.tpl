#!/usr/bin/env bash
# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu
function guess_runfiles() {
    if [ -d ${BASH_SOURCE[0]}.runfiles ]; then
        # Runfiles are adjacent to the current script.
        echo "$( cd ${BASH_SOURCE[0]}.runfiles && pwd )"
    else
        # The current script is within some other script's runfiles.
        mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        echo $mydir | sed -e 's|\(.*\.runfiles\)/.*|\1|'
    fi
}

# Adapted from: https://milhouse.dev/2015/11/20/writing-a-process-pool-in-bash/
function parallel() {
    local proc procs
    declare -a procs=() # this declares procs as an array

    failed=false
    morework=true
    while $morework; do
        if [[ "${#procs[@]}" -lt "%{pool_size}" ]]; then
            read proc || { morework=false; continue ;}
            eval "$proc" &
            procs["${#procs[@]}"]="$!"
        fi

        for n in "${!procs[@]}"; do
            kill -0 "${procs[n]}" 2>/dev/null && continue

            # Check if the process failed or not
            wait "${procs[n]}"
            status=$?
            if [ $status -ne 0 ]; then
              failed=true
            fi

            unset procs[n]
        done
        sleep 0.1s
    done

    wait
    if $failed; then
      exit 1
    fi
}

RUNFILES="${PYTHON_RUNFILES:-$(guess_runfiles)}"

parallel <<EOF
%{push_statements}
EOF


