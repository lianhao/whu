#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <password file>"
    exit 1
fi

die()
{
    echo "Error: $1"
    exit 1
}

ssh_remote_run()
{
    local host=$1
    local pass=$2
    local user="ubuntu"
    local cmd=$3

    sshpass -p "$pass" ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $user@$host $cmd
}

check_ssh()
{
    local host=$1
    local pass=$2

    #ssh login into the host, and noop
    ssh_remote_run $host $pass ":" || die "SSH login to $host failed!"
}

check_nfs()
{
    local host=$1
    local pass=$2
    local checkfile="data/tmp$RANDOM$RANDOM$RANDOM"

    ssh_remote_run $host $pass "touch $checkfile" || die "Can not create file on NFS on host $host"
    ssh_remote_run $host $pass "rm -f $checkfile" || die "Can not delete file on NFS on host $host"
}

sshpass -V > /dev/null || die "Please install sshpass package..."

passfile="$1"

declare -a HOST
declare -a PASS
count=0
while read -r line
do
    HOST[$count]=`echo $line | cut -d' ' -f1`
    PASS[$count]=`echo $line | cut -d' ' -f2`
    count=$(( $count + 1 ))
done < $passfile

for (( i=0; i<${#HOST[@]}; i++));
do
    echo "start to check ${HOST[$i]} ..."
    check_ssh ${HOST[$i]} ${PASS[$i]}
    check_nfs ${HOST[$i]} ${PASS[$i]}
    echo "host ${HOST[$i]} verified."
done
