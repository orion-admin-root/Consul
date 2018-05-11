#!/bin/sh
n=1
zero=0
number=1
task_name="consul_hdect/hdect_"
consul_address="http://sah2consul.be.softathome.com:8500" #Consul address
count=-1
for fn in `curl -s "${consul_address}/v1/kv/consul_hdect/?keys" | jq '.[] | select(endswith("/"))'`; do #Counting number of directories
    count=$(( count+1 ))
done
echo "There are $count directories"
session_id=$(curl -s -XPUT "${consul_address}/v1/session/create" -d "{\"Name\": \"${task_name}\"}"  | jq -r '.ID') #Creating session in Consul
echo "Session ID: $session_id"
while [ $n -le $count ] #Attempting Lock on all directories, stops when a lock is acquired
do
  if [ $number = 10 ]
  then
    zero=''
  else
    :
  fi
  task_name="consul_hdect/hdect_"
  lock=$(curl -s -XPUT "${consul_address}/v1/kv/${task_name}${zero}${number}/.lock?acquire=${session_id}") #Acquiring Lock
  if [ $lock = 'true' ] #Testing if Lock was acquired
    then
      echo "Lock acquired at ${task_name}${zero}${number}"
      result=$(curl -s -XPUT "${consul_address}/v1/kv/${task_name}${zero}${number}/.lock?release=${session_id}") #Releasing Lock
      "${result}" == "true" && echo "Lock released"
      echo "Destroying the session"
      result=$(curl -s -XPUT "${consul_address}/v1/session/destroy/${session_id}") #Destroying Session
      "${result}" == "true" && echo "Session destroyed"
      exit
    else #Lock was not acquired, attempts to Lock next directory
      echo "Access denied"
      n=$(( n+1 ))
      number=$(( number+1 ))
  fi
done
