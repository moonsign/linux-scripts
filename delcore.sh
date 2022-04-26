#!/bin/bash
_usage() {
    echo "usage:delcore.sh Rename coredump file name to core.[process]."
    echo "      Deal with directory: user home, bin and fbin every 10 min by default."
    echo "      Use \"delcore.sh [INTERVAL]\" to change sleeping interval."
    echo "      Use \"delcore.sh [DIRECTORY]\" to deal with expected directory once."
    echo "      Use \"delcore.sh [-h/-help]\" to show the usage."
    echo
}
_mvcore() {
    if [ -d $1 ]; then
        cd $1
        echo "Dealing with directory: $(pwd)."
        for corefile in $(ls -tr core*); do
            extname=$(file -Pelf_phnum=10000 $corefile | awk 'BEGIN{FS="from '\''|'\''"}{gsub("  *","_",$2);split($2,tmp,"/");print tmp[length(tmp)]}')
            echo mv -f $corefile core.$extname.
            mv -f $corefile core.$extname
        done
    else
        echo "$1: No such directory."
        _usage
        exit 0
    fi
}
if [ $1 ]; then
    if [ ! $(echo $1 | sed 's/[0-9]//g') ]; then
        if [ -d "$1" ]; then
            until [ "$input" = "1" -o "$input" = "2" ]; do
                echo "What do you mean by \""$1"\"?"
                echo "1.Deal with \""$(
                    cd $1
                    pwd
                )"\", or"
                echo "2.Make me sleep every" $1 "minutes."
                read input
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
    elif [ $1 = "-h" -o $1 = "-help" ]; then
        _usage
        exit 0
    else
        _mvcore $1
        exit 0
    fi
else
    interval=10
fi
if [ $(uname) = "Linux" ]; then
    procnum=2
else
    procnum=1
fi
if [ $(ps -ef | grep delcore.sh | grep -v grep | wc -l) -gt "$procnum" ]; then
    echo "delcore.sh is running already =)"
    exit 0
fi
_usage
while [ 1 ]; do
    _mvcore ${HOME}
    _mvcore ${HOME}/bin
    _mvcore ${HOME}/fes_bin
    echo
    echo Sleeping for $interval min...
    sleep $(expr $interval \* 60)
    echo
done
