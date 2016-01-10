#!/bin/bash

FILE_CFG_NAME=info.cfg
FILE_CFG=$(dirname $0)/$FILE_CFG_NAME
DIR_PROJ=$(dirname $0)/proj # clone project here
DIR_BAK=$(dirname $0)/bak # make bak here
DIR_TMP=$(dirname $0)/tmp # tmp files

## head

options(){

    OPTIONS=$(getopt -o g:p:ch -l get:,post:,clean,help -- "$@")

    if [ $? -ne 0 ]; then
	echo "getopt error"
	exit 1
    fi

    eval set -- $OPTIONS

    while true; do
	case "$1" in
	    -h|--help) HELP=1 ;;
	    -c|--clean) CLEAN=1 ;;
	    -g|--get) GET=1;OPTION_PROJECT="$2"; shift; ;;
	    -p|--post) POST=1;OPTION_PROJECT="$2"; shift; ;;
	    --) shift ; break ;;
	    *) echo "unknown option: $1" ; exit 1 ;;
	esac
	shift
    done

    if [ $# -ne 0 ]; then
	echo "unknown option(s): $@"
	exit 1
    fi
}

# $1 length 
# $2 pattern
gen_name(){
    cat /dev/urandom | tr -cd ${2:-"a-z"} | head -c ${1:-"32"}
}
gen_login(){
    echo $(gen_name 20)
}
gen_password(){
    echo $(gen_name $[ 40 + $[ RANDOM % 20 ] ] 'a-zA-Z0-9')
}

# $1 project name [name] 
# $2 project directory path [path]
__bak_mv(){
    rm -rf $DIR_BAK/"$1"
    if [ -d "$2" ]; then
	mkdir $DIR_BAK/"$1"
	mv "$2" $DIR_BAK/"$1"
    fi
}

__init(){
    if [ ! -d $DIR_PROJ ]; then
	mkdir $DIR_PROJ 
    fi
    if [ ! -d $DIR_BAK ]; then
	mkdir $DIR_BAK 
    fi
    if [ ! -d $DIR_TMP ]; then
	mkdir $DIR_TMP 
    fi
}

# $1 project name [name] 
# $2 [host]
__init_project(){
    if [ ! -d $DIR_PROJ/"$1" ]; then
	cd $DIR_PROJ
	git clone "$2"
    fi
}

# return first host from hosts string with delimeter '@'
# $1 [hosts]
__get_host(){
    echo $1 | cut -d@ -f1
}

# $1 [hosts]
__get_hosts_arr(){
    echo $1 | $(awk '{split($0,a,"@")} END{for(i in a) print a[i]}')
}

# $1 project name [name]
# $2 project path [path]
# $3 hosts
# $4 pass
post(){

    cd $DIR_PROJ/"$1"
    git filter-branch --tree-filter 'rm -rf *' --force HEAD
    local tar=$DIR_TMP/"$1".tar 
    local gpg=$DIR_PROJ/"$1".gpg

    tar -cvf $tar "$2"
    gpg --output $gpg --symmetric --personal-cipher-preferences 'AES256' --passphrase "$4" $tar
    rm $tar
    git add .
    git commit
    local hosts=__get_hosts_arr "$3";
    for i in $HOSTS
    do
	:
	git push $i --force
    done
}

# $1 project name [name]
# $2 project path [path]
# $3 hosts
# $4 pass
get(){
    bak_mv;

    cd $DIR_PROJ/"$1"
    git reset --hard HEAD 
    git pull $host
    local tar=$DIR_TMP/"$1".tar 
    gpg -d -o $tar --passphrase "$4"
    mkdir "$2"
    tar -xvf $tar -C "$2"
    rm $tar
}

clean(){
    rm -rf $DIR_BAK
    rm -rf $DIR_TMP
}

help(){
    echo "Help info: ..."
}

# $1 args
main(){
    options "$@";
    if [ "$HELP" = 1 ]; then
	help;
    elif [ "$CLEAN" = 1 ]; then
	clean;
    elif [ "$GET" = 1 ] || [ "$POST" = 1 ]; then

	__init;
	local lcfg=$DIR_TMP/$FILE_CFG_NAME.tmp
	cat $FILE_CFG | \
	    sed -n '/name='$OPTION_PROJECT'/,/^#/p ' \
	    | sed '$d' > $lcfg	

	source $lcfg
	
	if [ "$GET" = 1 ]; then
	   get $name $path $hosts $pass; 
	elif [ "$POST" = 1 ]; then
	   post $name $path $hosts $pass; 
	fi
    fi
    
}

## body
main "$@";

#    local project_name=${echo "" | awk -F@ 'print $NF'} 

