# !/usr/bin/env bash

mkdir -p tmp
[ -e tmp/in  ] && rm tmp/in
[ -e tmp/out ] && rm tmp/out
mkfifo tmp/in
mkfifo tmp/out
netcat -q 10 irc.osmarks.net 6667 < tmp/in > tmp/out &
# change "irc.osmarks.net" to the server address
# "-q 10" in my netcat version tells it to wait before writing, you might need to use something else
# (see <https://superuser.com/q/261900>)
printf ":pig.sh STARTPLZ\r\n" > tmp/out &
bqn pig.bqn run > tmp/in < tmp/out
