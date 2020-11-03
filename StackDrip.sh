#!/bin/bash

#Globals
stacklocation="/tmp/stack"
stackmaxsize=10
stackmaxunit=m
stackwait=15

#Argument 1: Directory to process
targetdir=$1

#Argument 2: Destination code
targetdst=$2

#Argument 1: Action code
targetact=$3

#Functions
function init() {
    echo "Initializing.."
    mkdir "$stacklocation"
}

function loop() { 
    for i in "$1"/*
    do
        if [ -d "$i" ]; then
            loop "$i"
        elif [ -e "$i" ]; then
            stack "$i"
        fi
    done
}

function stack() {
    stacksize=$(du -s$stackmaxunit $stacklocation | cut -f 1)
    filesize=$(du -s$stackmaxunit $1 | cut -f 1)
    
    if [ $((stacksize + filesize > stackmaxsize)) = 1 ]; then
        send
        wait
    fi
    
    echo "Stack ${1##*/} into $stacklocation/${1%/*}"
    mkdir -p "$stacklocation/${1%/*}"
    cp "$1" "$stacklocation/${1%/*}"
}

function send() {
    echo "Sending stack.."
    workingdir=$PWD
    cd $stacklocation && zip -r "$stacklocation.zip" * && curl -X POST -T "$stacklocation.zip" -H "filename: $targetdst"_$targetact"_stack.zip" http://localhost:9010/contentListener && cd $workingdir
    
    echo "Clear stack"
    rm -rf "$stacklocation.zip" "$stacklocation"
}

function wait() {
    echo "Waiting for $stackwait seconds.."
    sleep $stackwait
}

#Main
init
loop $targetdir
send
