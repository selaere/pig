# !/usr/bin/env bash

mkdir -p /tmp/pig
mkdir -p log
[ -e /tmp/pig/in  ] && rm /tmp/pig/in
[ -e /tmp/pig/out ] && rm /tmp/pig/out
mkfifo /tmp/pig/in
mkfifo /tmp/pig/out
logfile=$(date +log/%F.pig.log)
(
while true; do 
    (
        printf ":pig.sh STARTPLZ\r\n" > /tmp/pig/out
        # echo "finished" >2
    ) &
    # change "irc.osmarks.net" to the server address
    # "-w 10" in my netcat version tells it to wait before writing, you might need something else
    # (see <https://superuser.com/q/261900>)
    netcat -w 60 irc.osmarks.net 6667 < /tmp/pig/in > /tmp/pig/out
done
) &
# printf ":pig.sh STARTPLZ\r\n" > /tmp/pig/out &
$bqn pig.bqn run > /tmp/pig/in < /tmp/pig/out 2> >(tee -a $logfile >&2)
