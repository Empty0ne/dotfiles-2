#!/bin/sh
#
# z3bra - (c) wtfpl 2014
# Fetch infos on your computer, and print them to stdout every second.

clock() {
    date '+%Y-%m-%d %H:%M'
}

battery() {
    BATC=/sys/class/power_supply/BAT1/capacity
    BATS=/sys/class/power_supply/BAT1/status

    test "`cat $BATS`" = "Charging" && echo -n '+' || echo -n '-'

    sed -n p $BATC
}

volume() {
    amixer get Master | grep -P -o '\[[0-9]+%\]'
}

cpuload() {
    LINE=`ps -eo pcpu |grep -vE '^\s*(0.0|%CPU)' |sed -n '1h;$!H;$g;s/\n/ +/gp'`
    bc <<< $LINE
}

memused() {
  free -m | head -n 3 | tail -n 2 | tr '\n' ' ' | awk '{printf("%2.1fG/%0.2gG\n" ,($10/1024),($2/1024))}'
}

network() {
    read lo int1 int2 <<< `ip link | sed -n 's/^[0-9]: \(.*\):.*$/\1/p'`
    if iwconfig $int1 >/dev/null 2>&1; then
        wifi=$int1
        eth0=$int2
    else
        wifi=$int2
        eth0=$int1
    fi
    ip link show $eth0 | grep 'state UP' >/dev/null && int=$eth0 ||int=$wifi

    #int=eth0

}

groups() {
    cur=`xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}'`
    tot=`xprop -root _NET_NUMBER_OF_DESKTOPS | awk '{print $3}'`

    for w in `seq 0 $((cur - 1))`; do line="${line}="; done
    line="${line}|"
    for w in `seq $((cur + 2)) $tot`; do line="${line}="; done
    echo $line
}

nowplaying() {
    cur=`mpc current`
    # this line allow to choose whether the output will scroll or not
    test "$1" = "scroll" && PARSER='skroll -n20 -d0.5 -r' || PARSER='cat'
    test -n "$cur" && $PARSER <<< $cur || echo "- stopped -"
}

alsamixer="if pidof alsamixer; then pkill alsamixer; else  urxvtc -name alsamixer -e alsamixer &; fi"
htop="if pidof htop; then pkill htop; else  urxvtc -name alsamixer -e htop &; fi"
ncmpcpp="if pidof ncmpcpp; then pkill ncmpcpp; else  urxvtc -name alsamixer -e ncmpcpp &; fi"  
# This loop will fill a buffer with our infos, and output it to stdout.
while :; do
    buf="%{r}%{F#FF6A9FB5}"
    buf="${buf} %{A:$htop:}⮦    $(cpuload)%% "
    buf="${buf} | ⮡: $(memused)%{A}"
    buf="${buf} |%{A:$alsamixer:} ⮞ $(volume)%%%{A}"
    buf="${buf} |%{A:$ncmpcpp:} ⮕ $(nowplaying)%{A}"
    buf="${buf} |%{A:gsimplecal&:} ⮖ $(clock)%{A}"

    echo $buf
    # use `nowplaying scroll` to get a scrolling output!
    sleep 0.5 # The HUD will be updated every second
done
