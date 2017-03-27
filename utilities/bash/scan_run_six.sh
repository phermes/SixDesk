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

sixdeskmessleveldef=0
sixdeskmesslevel=$sixdeskmessleveldef

# - load environment
source ${SixDeskDev}/dot_profile

kinit -R 




function how_to_use() {
    cat <<EOF
   `basename $0` [action] [option]

    actions
    -f      correct directory structure
    -i      run incomplete cases on LSF for all cases defined in scan_definitions
    -s      submit jobs to BOINC for all cases defined in scan_definitions
    -l      unlock all for all studies
    -R      retreive results for all jobs listed in scan_definitions. can be combined with -c and -w
    -O      Overview: show submission status for all jobs in scan
    -T      show status of simulations in scan
            will give information about jobs in queue, finished but unretrieved jobs and retrieved jobs

    options
    -c      perform action only for the specific study given as argument
    -P      retrieve in parallel
    -w      repeat periodically; works for actions -a, -T
    -S      selective submission [see man of run_six.sh]
    -q      quiet mode; parses output to different files




EOF
}


### DEFINE FUNCTIONS





function initialize_scan(){

    if ! ${scan_chroma}; then
	SCAN_QP="0.0"
    fi

    if ! ${scan_octupoles}; then
	SCAN_OC="0.0"
    fi    

}


function do_submit(){

    flags="-a"

    if ${quiet} || ${parallel}; then
	flags="${flags} -q"
    fi

    if ${selective}; then
	flags="${flags} -S"
    fi

    if ! ${parallel}; then
	$SixDeskDev/run_six.sh ${flags}
    else
	echo "Parallel submission launched for ${study}"
	$SixDeskDev/run_six.sh ${flags} > output.${study} &
	echo "waiting 60s"
	sleep 60	
    fi


    }

function submit_status(){
    echo "--------------------------------"
    echo "Study: ${study}"
    tail -n 1 output.${study}
    echo "--------------------------------"    
}




function get_mask_name(){

    mask=${mask_prefix}

    if ${scan_chroma}; then
	mask="${mask}-QP-${qp}"
    fi
    
    if ${scan_octupoles}; then
	mask="${mask}-OC-${oc}"
    fi
    
}

function retrieve_job(){
    kinit -R
    echo "-->  Workspace for retrieving:  ${workspace}" 
    echo "-->  Retrieving for targetjob:  ${study}"
    ${SixDeskDev}/run_results
}


function scan_loop() {


    if [[ $# -eq 0 ]] ; then
	echo 'ERROR: no argument given to scan_loop'
	exit 1
    fi
   
    
    if ${qcase}; then
	study=${jobstring}
	if ! ${skipenv}; then
	    set_env_to_mask >> output.${study}
	fi
	for var in "$@"
	do
	    $var
	done
	
    elif ${scan_masks};then
	for study in ${mask_names}; do

	    if ! ${skipenv}; then
		set_env_to_mask >> output.${study}
	    fi
	    
	    for var in "$@"
	    do
		$var
	    done	    
	done
	
    elif ${scan_chroma} || ${scan_octupoles} ; then
	
        initialize_scan
	
        for qp in ${SCAN_QP}
        do
	    for oc in ${SCAN_OC}
	    do
	       get_mask_name
	       study=${mask}
	       if ! ${skipenv}; then
		   set_env_to_mask >> output.${study}
	       fi
		       
	       for var in "$@"
	       do
		   $var
	       done
		       
	   done
        done
    fi




    }











function get_status(){

    BOINCNAME="${workspace}_${mask}"
    BOINCDIR=/afs/cern.ch/work/b/boinc/boinc/${BOINCNAME}
    NRES=$(ls ${BOINCDIR}/results/ | wc -l)                                           # ready to recieve
    
    NPEN=$(ls ${BOINCDIR}/work/    | wc -l)	                                      # pending
    NREC=$(find ../track/${mask}/*/*/*/*/*/*/ -type f -name "*.10.gz" | wc -l)        # recieved

    if ${quiet}; then

	echo "--> NAME         ${mask}" >> ${OUTFILE}
	echo "--> PENDING      $NPEN"   >> ${OUTFILE} 	    
	echo "--> COMPLETED    $NRES"   >> ${OUTFILE}
	echo "--> RECIEVED     $NREC"   >> ${OUTFILE}
	echo ""                         >> ${OUTFILE}
    else
	echo "--> NAME         ${mask}"
	echo "--> PENDING      $NPEN" 	    
	echo "--> COMPLETED    $NRES"
	echo "--> RECIEVED     $NREC"
	echo 
    fi
    
    }


function list_status() {

    if ${scan_chroma} && ${scan_octupoles}
    then
        for x in $SCAN_QP
	do
	    for y in $SCAN_OC
	    do
		kinit -R 
		mask="${mask_prefix}-${x}-${y}"
		get_status
	    done
        done
	
    elif ${scan_masks} && ! ${qcase}; then
	for mask in ${mask_names}; do
	    get_status
	done
	
    elif ${qcase}; then
	mask=${jobstring}
	get_status
    fi    	    

	    
    }





function set_env_to_mask(){   
    ${SixDeskDev}/set_env.sh -d ${study} #> /dev/null 2>&1
}










sear_string=false
submit=false
fix=false
unlock=false
retrieve=false
incomplete=false
qcase=false
parallel=false
quiet=false
progress=false
status=false
substatus=false
repeat=false
#jobstringQ=false
skipenv=false
selective=false

# get options (heading ':' to disable the verbose error handling)
while getopts  "fhwlPc:iqTOSsRb" opt ; do
    case $opt in
        f)
            fix=true
            ;;
        q)
            quiet=true
            ;;
        O)
            substatus=true
            ;;	
        S)
            selective=true
            ;;	
        c)
            qcase=true
	    jobstring=${OPTARG}
            ;;
        T)
            status=true
            ;;	
        P)
            parallel=true
            ;;	
        i)
            incomplete=true
            ;;
        w)
            repeat=true
            ;;	
        R)
            retrieve=true
            ;;
	
        l)
            unlock=true
            ;;
	s)
	    submit=true
	    ;;
	h)
	    how_to_use
	    exit 1
	    ;;
	:)
	    how_to_use
	    echo "Option -$OPTARG requires an argument."
	    exit 1
	    ;;
	\?)
	    how_to_use
	    echo "Invalid option: -$OPTARG"
	    exit 1
	    ;;
    esac
done
shift "$(($OPTIND - 1))"














if ${status}; then
    
    OUTFILE="scan_status.dat"
    DTETIME=$(date)

    if ${quiet}; then
	echo "--> DATE: ${DTETIME}" >> ${OUTFILE}
	echo " "                    >> ${OUTFILE}
    fi


    while true; do
	list_status
	if ! ${repeat}; then
	    exit
	else
	    echo " "
	    sleep 60
	    echo "--> DATE         ${DTETIME}"
	fi
    done
fi




if ${incomplete}; then
    scan_loop ${SixDeskDev}/run_incomplete_cases_lsf	    		
fi





if ${retrieve}; then
    if ${qcase}; then
	study=${jobstring}
	retrieve_job
    else
        while true; do
	    scan_loop retrieve_job
	    if ${repeat}; then
		echo "Waiting 60s"
		sleep 60
	    else
		exit
	    fi
	done
    fi
fi

   

if ${submit}; then
    scan_loop do_submit 

    
    if ${parallel}; then
	echo "Submission Status"
	while true; do
	    scan_loop submit_status 
	    wait 1
	done
    fi
fi


if ${unlock}; then
    echo "Option unlock all"
    scan_loop ./unlock_all
fi





if ${fix}; then  
    scan_loop $SixDeskDev/run_six.sh -f 
fi

if ${substatus}; then
    skipenv=true
    while true; do
	clear
	echo "Submission Status"
	echo
	scan_loop submit_status
	sleep 1
    done
fi











exit

