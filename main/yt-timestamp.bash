#!/usr/bin/env bash

url="$1"
czas="$2"

h=$(( 10#${czas:0:2} ))
m=$(( 10#${czas:2:2} ))
s=$(( 10#${czas:4:2} ))

sekundy_total=$(( h * 3600 + m * 60 + s ))

# (skips 0h, 0m)
format_laczony=""
[[ $h -gt 0 ]] && format_laczony+="${h}h"
[[ $m -gt 0 ]] && format_laczony+="${m}m"
[[ $s -gt 0 ]] && format_laczony+="${s}s"

sep="?"
[[ "$url" == *"?"* ]] && sep="&"

# Wyjście
#echo "Wersja (sekundy): ${url}${sep}t=${sekundy_total}s"
#echo "Wersja (łączona): ${url}${sep}t=${format_laczony}"
echo -n "${url}${sep}t=${sekundy_total}s"
