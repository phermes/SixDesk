#!/bin/bash

source ./scan_definitions
source ./sixdeskenv


# ------------------------------------------------------------------------------
# preparatory steps
# ------------------------------------------------------------------------------

export sixdeskhostname=`hostname`
export sixdeskname=`basename $0`
export sixdeskroot=`basename $PWD`
export sixdeskwhere=`dirname $PWD`
# Set up some temporary values until we execute sixdeskenv/sysenv
# Don't issue lock/unlock debug text (use 2 for that)
export sixdesklogdir=""
export sixdesklevel=1
export sixdeskhome="."
export sixdeskecho="yes!"

if [ ! -s ${SixDeskDev}/dot_profile ] ; then
    echo "${SixDeskDev}"
    echo "dot_profile is missing!!!"
    exit 1
fi

if [ ! -s ${SixDeskDev}/dot_scan ] ; then
    echo "${SixDeskDev}"
    echo "dot_scan is missing!!!"
    exit 1
fi


sixdeskmessleveldef=0
sixdeskmesslevel=$sixdeskmessleveldef

# - load environment
source ${SixDeskDev}/dot_profile
source ${SixDeskDev}/dot_scan

kinit -R 




function how_to_use() {
    cat <<EOF
   `basename $0` [action] [option]
    perform actions and options for a set of studies. actions and options identical to those of run_six.sh:
EOF

    ${SixDeskDev}/run_six.sh -h 
}



# get the arguments

args=$@
echo "${args}"



function doCommand(){
    echo "running command" ${1}
    ${1}
}


function run_run_six(){
    doCommand "${SixDeskDev}/run_six.sh ${args}"
}




if [ "${args}" = "-h" ]; then
    how_to_use
    exit 0
fi




scan_loop run_run_six






exit


