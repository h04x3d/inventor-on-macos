#!/bin/bash
# Kill .NET "ngen executeQueuedItems" runs that deadlock under Wine on macOS
# (alive > 90 s with < 3 s CPU), plus their NGen worker processes.
while true; do
  ps -axww -o pid=,etime=,time=,command= | grep -E 'ngen\.exe executeQueuedItems' | grep -v grep |
  while read -r pid et cpu rest; do
    s=$(echo "$et" | awk -F'[:-]' '{n=NF; t=$n+$(n-1)*60; if(n>2)t+=$(n-2)*3600; if(n>3)t+=$(n-3)*86400; print t}')
    c=$(echo "$cpu" | awk -F: '{print $1*60+$2}')
    if [ "$s" -gt 90 ] && [ "${c%.*}" -lt 3 ]; then
      echo "$(date +%T) killing hung ngen $pid (age ${s}s cpu ${c}s)"
      kill "$pid"; pkill -f 'mscorsvw.exe -UseCLSID'
    fi
  done
  # idle .NET optimization services (keep setup waiters from blocking)
  ps -axww -o pid=,time=,command= | grep -E "mscorsvw.exe" | grep -v grep | while read -r p t r; do pgrep -f "ngen.exe" >/dev/null || { echo "$(date +%T) stopping idle mscorsvw $p"; kill $p; }; done
  sleep 10
done
