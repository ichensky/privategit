#!/bin/sh

DIR_PROJ=$(dirname $0)/proj # clone project here
BAK_DIR=$(dirname $0)/bak # make bak here

## head

options(){

	OPTIONS=$(getopt -o gpch -l get:,post:,clean,help -- "$@")

	if [ $? -ne 0 ]; then
	    echo "getopt error"
	    exit 1
	fi

	eval set -- $OPTIONS

	while true; do

	    case "$1" in
		-h|--help) HELP=1 ;;
		-c|--clean) CLEAN=1 ;;
		-g|--get) GET=1; DIR_PROJ_PROJECT="$2" ; shift ;;
		-p|--post) POST=1; DIR_PROJ_PROJECT="$2" ; shift ;;
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

gen_name(){
cat /dev/urandom | tr -cd 'a-f' | head -c 32
}

bak_mv(){
    rm -rf $BAK_PROJ/$PROJECT_NAME
   if [ -d $PROJECT ]; then
     mkdir $BAK_PROJ/$PROJECT_NAME
	mv $PROJECT $BAK_PROJ/$PROJECT_NAME
    fi
}

init(){
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

init_project(){
    if [ ! -d $DIR_PROJ/$PROJECT_NAME ]; then
	cd $DIR_PROJ
	git clone $HOST
    fi
}

post(){
    
    init_project;
    cd $DIR_PROJ/$PROJECT_NAME
    git filter-branch --tree-filter 'rm -rf .' HEAD
    local tar=$DIR_TMP/$PROJECT_NAME.tar 
    local gpg=$DIR_PROJ/$PROJECT_NAME.gpg

    tar -cvf $tar $PROJECT
    gpg --output $gpg --symmetric --personal-cipher-preferences 'AES256' $tar
    rm $tar
    git add .
    git commit
    for i in $HOSTS
    do
	     :
	     
	     git push $i -f
    done
}

get(){
    bak_mv;
    init_project;

    cd $DIR_PROJ/$PROJECT_NAME 
    git reset --hard HEAD 
    git pull $HOST 
    local tar=$DIR_TMP/$PROJECT_NAME.tar 
    gpg -d -o $tar --passphrase $PASS
    mkdir $PROJECT
    tar -xvf $tar -C $PROJECT
    rm $tar
    }

## body

init;
options "$@";

local hosts="$(awk '{split($0,a,":")} END{for(i in a) print a[i]}')"

    local project_name=${echo "" | awk -F@ 'print $NF'} 
# push "aaa" "bbb";

