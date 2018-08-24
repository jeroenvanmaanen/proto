#!/usr/bin/env bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
SCRIPT="$(basename "$0" .sh)"
SRC="$(dirname "${BIN}")"
PROTO="${SRC}/proto"
PROJECT="$(dirname "${SRC}")"
TARGET="${PROJECT}/target/html"

declare -a FLAGS_INHERIT
source "${BIN}/verbose.sh"
source "${BIN}/lib.sh"

if [ ".$1" = '.-p' ]
then
    shift
    PROTO="$1"
    shift
fi

if [ ".$1" = '.-t' ]
then
    shift
    TARGET="$1"
    shift
fi

if [ ".$1" = '.--' ]
then
    shift
fi

log "PROTO=[${PROTO}]"

log "TARGET=[${TARGET}]"
mkdir -p "${TARGET}"
TARGET="$(cd "${TARGET}" ; pwd)"

log "Generate: [${PROTO}] [${TARGET}]"

PROTO_SRC="$(dirname "${PROTO}")"

if [ -d "${PROTO_SRC}/resources" ]
then
    cp -r "${PROTO_SRC}/resources"/* "${TARGET}/."
fi

for FILE in "$@"
do
    F="${FILE#${PROTO}}"
    log "FILE: [${PROTO}]: [${F}]"
    CONTEXT=''

    "${BIN}/include.sh" "${FLAGS_INHERIT[@]}" "${PROTO}" "${F}" \
        | (
            MENU_DEPTH='0'
            ROOT_PATH=''
            while read LINE
            do
                case "${LINE}" in
                \~*)
                    NEW_CONTEXT='MENU'
                    ;;
                \|*)
                    NEW_CONTEXT='TABLE'
                    ;;
                '')
                    NEW_CONTEXT='P'
                    ;;
                *)
                    NEW_CONTEXT=''
                esac
                if [ ".${CONTEXT}" != ".${NEW_CONTEXT}" ]
                then
                    case "${CONTEXT}" in
                    MENU)
                        while [ "${MENU_DEPTH}" -gt 0 ]
                        do
                            echo "</div>"
                            MENU_DEPTH=$[$MENU_DEPTH-1]
                        done
                        ;;
                    TABLE)
                        echo '</table>'
                        ;;
                    esac
                    case ".${CONTEXT}.${NEW_CONTEXT}" in
                    ..P)
                        echo '<p>'
                        ;;
                    esac
                    case "${NEW_CONTEXT}" in
                    MENU)
                        MENU_DEPTH=0
                        ;;
                    TABLE)
                        echo '<table>'
                        ;;
                    esac
                fi
                CONTEXT="${NEW_CONTEXT}"
                log "LINE=[${LINE}]"
                case "${LINE}" in
                \>*)
                    RELATIVE="$(echo "${LINE}" | sed -e 's/^> *//')"
                    OUTPUT="${TARGET}${RELATIVE}.html"
                    log "Writing to [${OUTPUT}]"
                    ROOT_PATH="$(dirname "${RELATIVE}" | sed -e 's:/[.][.]:/||:g' -e 's:/[^|/][^/]*:/..:g' -e 's:/[^/][^|/][^/]*:/..:')"
                    log "XXX=[$(dirname "${RELATIVE}")]"
                    log "ROOT_PATH[A]=[${ROOT_PATH}]"
                    while [ ".${ROOT_PATH#*/../\|\|}" != ".${ROOT_PATH}" ]
                    do
                        ROOT_PATH="$(echo "${ROOT_PATH}" | sed -e 's:/../||/:/:')"
                    done
                    ROOT_PATH="${ROOT_PATH#/}"
                    log "ROOT_PATH=[${ROOT_PATH}]"
                    mkdir -p "$(dirname "${OUTPUT}")"
                    exec > "$OUTPUT"
                    ;;
                \#*)
                    N=0
                    STRIPPED="${LINE}"
                    while test-prefix '\#' "${STRIPPED}"
                    do
                        N=$[$N+1]
                        STRIPPED="${STRIPPED#\#}"
                    done
                    wrap-tag "h${N}" "${STRIPPED}"
                    ;;
                \~*)
                    N=0
                    STRIPPED="${LINE}"
                    while test-prefix '\~' "${STRIPPED}"
                    do
                        N=$[$N+1]
                        STRIPPED="${STRIPPED#\~}"
                    done
                    while [ "${MENU_DEPTH}" -lt "${N}" ]
                    do
                        echo "<div class='menu'>"
                        MENU_DEPTH=$[$MENU_DEPTH+1]
                    done
                    while [ "${MENU_DEPTH}" -gt "${N}" ]
                    do
                        echo "/<div>"
                        MENU_DEPTH=$[$MENU_DEPTH-1]
                    done
                    wrap-tag-class 'div' 'menu-item' "${STRIPPED}"
                    ;;
                '')
                    ;;
                *)
                    expand-line "${LINE}"
                esac
            done
        )
done

