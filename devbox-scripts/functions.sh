#!/bin/bash

TRACE_DEPTH=${TRACE_OFFSET:-0}
TRACE_STACK=${TRACE_NAME:-''}


# Import common functions from Devstack
source ./functions-common

# Import settings
if [[ -f "./muranorc" ]]; then
    source ./muranorc
fi
source ./muranorc-defaults


GetOSVersion

# Import distro-based scripts for Murano
case $os_VENDOR in
    'Ubuntu')
        source ./murano-functions-debian
    ;;
    'Red Hat'|'CentOS')
        source ./murano-functions-redhat
    ;;
    *)
        die "'$os_VENDOR' isn't supported by this script."
    ;;
esac


# Define additional functions
function log {
    l='          '
    printf "%s%s\n" "${l:0:$TRACE_DEPTH}" "$@" | tee --append $LOG_FILE
}

function echo_() {
    l='          '
    printf "%s%s\n" "${l:0:$TRACE_DEPTH}" "$@" | tee --append $LOG_FILE
}

function echo_h1() {
    l='**********'
    printf "%s%s\n" "${l:0:$TRACE_DEPTH}" "$@" | tee --append $LOG_FILE
}

function echo_h2() {
    l='=========='
    printf "%s%s\n" "${l:0:$TRACE_DEPTH}" "$@" | tee --append $LOG_FILE
}

function echo_h3() {
    l='----------'
    printf "%s%s\n" "${l:0:$TRACE_DEPTH}" "$@" | tee --append $LOG_FILE
}

function trace_in() {
    l='----------'
    # Trace in
    TRACE_STACK="$TRACE_NAME $1"
    shift
    TRACE_DEPTH=$(( TRACE_DEPTH + 1 ))
    echo_h3 " >>> ${TRACE_STACK##* }($@)"
}

function trace_out() {
    l='----------'
    # Trace out
    echo_h3 " <<< ${TRACE_STACK##* }()"
    TRACE_STACK=${TRACE_STACK% *}
    TRACE_DEPTH=$(( TRACE_DEPTH - 1 ))
}


function pip_install() {
    trace_in pip_install "$@"

    log "** Installing pip packages '$@'"

    if [ -f "$pip_version_requirements" ]; then
        pip install --upgrade -r "$pip_version_requirements" "$@"
    else
        pip install --upgrade "$@"
    fi

    trace_out
}


function upgrade_pip() {
    trace_in upgrade_pip "$@"

    log "** Upgrading pip to '$1'"

    case "$1" in
        '1.4')
            echo 'pip<1.5' > "$pip_version_requirements"
            pip install --upgrade -r "$pip_version_requirements"
            rm /usr/bin/pip
            ln -s /usr/local/bin/pip /usr/bin/pip
        ;;
    esac

    trace_out
}


function replace {
    sed -i "s/$1/$2/g" "$3"
}


function insert_block_into_file() {
    local target_file=$1
    local insert_file=$2
    local pattern=$3

    if [[ -z "$pattern" ]]; then
        cat "$insert_file" >> "$target_file"
    else
        sed -ne "/$pattern/r  $insert_file" -e 1x  -e '2,${x;p}' -e '${x;p}' -i "$target_file"
    fi
}


function remove_block_from_file() {
    local target_file=$1
    local from_line=${2:-'#MURANO_CONFIG_SECTION_BEGIN'}
    local to_line=${3:-'#MURANO_CONFIG_SECTION_END'}

    if [[ -f "$config_file" ]]; then
        sed -e "/^${from_line}/,/^${to_line}/ d" -i "$target_file"
    fi
}
