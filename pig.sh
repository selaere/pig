# !/usr/bin/env bash

mkdir -p /tmp/pig
mkdir -p log
[ -e /tmp/pig/in  ] && rm /tmp/pig/in
[ -e /tmp/pig/out ] && rm /tmp/pig/out
mkfifo /tmp/pig/in
mkfifo /tmp/pig/out
logfile=$(date +log/%F.pig.log)
( if true; then
    printf ":pig.sh STARTPLZ\r\n" &
    # change "irc.osmarks.net" to the server address
    # "-w 60" in my netcat version tells it to wait before writing, you might need something else
    # (see <https://superuser.com/q/261900>)
    netcat -w 60 irc.osmarks.net 6667
fi ) < /tmp/pig/in > /tmp/pig/out &
# printf ":pig.sh STARTPLZ\r\n" > /tmp/pig/out &
$bqn pig.bqn run > /tmp/pig/in < /tmp/pig/out 2> >(tee -a $logfile >&2)
