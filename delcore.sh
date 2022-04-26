#!/bin/bash
scriptname="$(basename $0)"
prompt=" > "

_usage() {
    echo ""
    echo "${scriptname}"
    echo "      Rename coredump file to core.[process]_[arg1]_[arg2]...[argn] and keep only the latest, periodically(per 10 min by default)."
    echo "      Default directories: user home, bin and fbin ."
    echo "usage"
    echo "      ${scriptname} [interval] - to process every [interval] mins."
    echo "      ${scriptname} [directory] - to process specified directory and exit."
    echo "      ${scriptname} [-h/-help] - to show this message."
    echo ""
}

_mvcore() {
    if [[ -d "$1" ]]; then
        cd "$1"
        echo "Renaming coredump files in \"${PWD}\"..."
        count=$(ls core* 2>/dev/null | wc -l)
        if [[ ${count} -eq 0 ]]; then
            echo "${prompt}Great! No coredump file found\(^o^)/"
            echo 
            return 0
        else
            echo "${prompt}${count} coredump file(s) found."
        fi
        for corefile in $(ls -tr core*); do
            ext="$(file -Pelf_phnum=10000 "${corefile}" | awk 'BEGIN{FS="from '\''|'\''"}{gsub("  *","_",$2);split($2,tmp,"/");print tmp[length(tmp)]}')"
            newname="core.${ext}"
            if [[ "${corefile}" == "${newname}" ]]; then
                echo "${prompt}Skipping \"${corefile}\""
            else
                echo "${prompt}Renaming \"${corefile}\"${prompt}\"${newname}\""
                cmd="mv -f \"${corefile}\" \"${newname}\""
                eval "${cmd}" 2>/dev/null
            fi
        done
        echo ""
    else
        echo "$1: No such directory."
        _usage
        return 1
    fi
}
if [[ $1 ]]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        if [[ -d "$1" ]]; then
            until [[ "${input}" =~ ^[12]$ ]]; do
                echo "What do you mean by \""$1"\"?"
                echo " 1: Rename coredump files in \""$(readlink -f $1)"\", or"
                echo " 2: Sleep for every" $1 "minutes."
                read -n1 input
            done
            case $input in
            1)
                _mvcore $1
                exit 0
                ;;
            2) interval=$1 ;;
            esac
        else
            interval=$1
        fi
    elif [[ "$1" =~ ^(-h|--help)$ ]]; then
        _usage
        exit 0
    else
        _mvcore $1
        exit 0
    fi
else
    interval=10
fi

pid="$(ps -ef | \grep ${scriptname} | \grep -v grep | \grep -v $$ | awk '{print $2}')"
if [[ ! -z "${pid}" ]]; then
    echo "${scriptname}(${pid}) is running already =)"
    exit 0
fi

while true; do
    _mvcore ${HOME}
    _mvcore ${HOME}/bin
    _mvcore ${HOME}/fes_bin
    echo "Sleeping for $interval min(s)..."
    sleep $(expr $interval \* 60)
    echo ""
done
