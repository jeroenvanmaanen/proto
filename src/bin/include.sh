#!/usr/bin/env bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
SCRIPT="$(basename "$0" .sh)"

declare -a FLAGS_INHERIT
source "${BIN}/verbose.sh"
source "${BIN}/lib.sh"

PROTO="$1" ; shift

function expand() {
    local BASE="$1"
    local CURRENT="$2"
    local FILE_PATH
    shift
    ( cat "${PROTO}${BASE}/${CURRENT}.proto" ; echo ) \
        | while read -r LINE
            do
                log "${CURRENT}: LINE=[${LINE}]"
                FILE_PATH="${LINE#@}"
                if [ ".${FILE_PATH}" != ".${LINE}" ]
                then
                    if test-prefix / "${FILE_PATH}"
                    then
                        :
                    else
                        log "Relative FILE_PATH=[${BASE}] [${FILE_PATH}]"
                        FILE_PATH="${BASE}${FILE_PATH}"
                    fi
                    "${BIN}/include.sh" "${FLAGS_INHERIT[@]}" "${PROTO}" "${FILE_PATH}"
                else
                    echo "${LINE}"
                fi
            done \
        | sed -e "/^> *\$/s; *\$; ${CURRENT};" -e "/^> *[^ /]/s;^> *;> ${BASE}/;"
}

for FILE_PATH in "$@"
do
    BASE="$(dirname "${FILE_PATH}" | sed -e '/[/]$/!s:$:/:')"
    FILE="$(basename "${FILE_PATH}" .proto)"
    log "[${PROTO}] [${BASE}] [${FILE}]"
    expand "${BASE}" "${FILE}"
done
