#!/usr/bin/false

SED_EXT=-r
case $(uname) in
Darwin*)
        SED_EXT=-E
esac
export SED_EXT

: ${BIN:=}
if [ -z "${BIN}" ]
then
    BIN="$(cd "$(dirname "$0")" ; pwd)"
fi

: ${ROOT_PATH:=}

LOG_TYPE="$(type -t log)"
echo "LOG_TYPE=[${LOG_TYPE}]" >&2
if [ ".${LOG_TYPE}" != '.function' ]
then
    source "${BIN}/verbose.sh"
fi

function test-prefix() {
    local PREFIX="$1"
    local STRING="$2"
    [ ".${STRING#${PREFIX}}" != ".${STRING}" ]
}

function expand-line() {
    local LINE="$*"
    local ROOT="$(echo "${ROOT_PATH}" | sed -e '/[^/]$/s:$:/:')"
    echo "${LINE}" \
        | sed "${SED_EXT}" \
            -e 's/[(][(]([^()]*)[|]([^()]*)[)][)]/<a href="\2">\1<\/a>/g' \
            -e 's/[[][[]([^[]*)[|]([^[]*)[]][]]/<input type="button" value="\1" data-url="\2">\&#xA0;<\/input>/g' \
            -e 's/<<([^<>]*)>>/<input type="text" value="\1">\&#xA0;<\/input>/g' \
            -e 's/[|]([^|]*)/<td>\1<\/td>/g' \
            -e '/^<td>/s/$/<\/tr>/' \
            -e '/^<td>/s/^/<tr>/' \
            -e "s:///:${ROOT}:"
}

function wrap-tag() {
    local TAG="$1"
    local CONTENT="$2"
    while test-prefix ' ' "${CONTENT}"
    do
        CONTENT="${CONTENT# }"
    done
    echo "<${TAG}>$(expand-line ${CONTENT})</${TAG}>"
}

function wrap-tag-class() {
    local TAG="$1"
    local CLASS="$2"
    local CONTENT="$3"
    local ATTRS=''
    if [ -n "${CLASS}" ]
    then
        ATTRS=" class='${CLASS}'"
    fi
    while test-prefix ' ' "${CONTENT}"
    do
        CONTENT="${CONTENT# }"
    done
    echo "<${TAG}${ATTRS}>$(expand-line ${CONTENT})</${TAG}>"
}
