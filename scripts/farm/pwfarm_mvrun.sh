#!/bin/bash

if [ -z "$PWFARM_SCRIPTS_DIR" ]; then
    source $( dirname $BASH_SOURCE )/__pwfarm_runutil.sh || exit 1
else
    source $PWFARM_SCRIPTS_DIR/__pwfarm_runutil.sh || exit 1
fi

ensure_farm_session

function usage()
{    
    cat <<EOF
usage: $( basename $0 ) [-o:] runid_src runid_dst

    Move good runs on farm.

    Note: You may operate on a hierarchy of runs. For example, if you have runs
'foo/x' and 'foo/y', you may move both in one operation via 'foo'.

OPTIONS:

    -o   Specify run owner, which is prepended to run ID. "nil" for no owner.

EOF
    exit 1
}

if [ $# == 0 ]; then
    usage
fi

if [ "$1" == "--field" ]; then
    field=true
    shift
else
    field=false
fi

owner=$( pwenv pwuser )
owner_override=false

while getopts "o:" opt; do
    case $opt in
	o)
	    owner="$OPTARG"
	    owner_override=true
	    ;;
	*)
	    exit 1
	    ;;
    esac
done

args="$@"
shift $(( $OPTIND - 1 ))
if [ $# != 2 ]; then
    usage
fi

runid_src="$1"
runid_dst="$2"

if ! $field; then
    __pwfarm_script.sh $0 --field $args || exit 1
else
    runid_src=$( build_runid "$owner" "$runid_src" )
    runid_dst=$( build_runid "$owner" "$runid_dst" )

    path_src=$( stored_run_path "good" "$runid_src" )
    if [ ! -e "$path_src" ]; then
	err "Cannot locate source. Expecting $path_src"
    fi
    path_dst=$( stored_run_path "good" "$runid_dst" )
    if ! mkdir -p "$( dirname $path_dst )"; then
	exit 1
    fi

    mv "$path_src" "$path_dst"
fi
