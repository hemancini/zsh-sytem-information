#!/bin/zsh

function _si_system_load() {
  local _title="☉ System load:"
  if [[ $(uname) == "Darwin" ]]; then
    echo "$_title $(top -l 1 -s 0 | grep "CPU usage" | awk '{print "" $3}')"
  else
    echo "$_title $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.1f%%", 100-$1 }')"
  fi
}

function _si_memory_usage() {
  local _title="☉ Memory Usage:"
  if [[ $(uname) == "Darwin" ]]; then
    installed_memory=$(sysctl -n hw.memsize)
    installed_memory_in_gb=$(bc <<<"scale=2; $installed_memory/1024/1024/1000")
    page_types=("wired down" "active" "inactive")
    all_consumed=0
    for page_type in "${page_types[@]}"; do
      consumed=$(vm_stat | grep "Pages ${page_type}:" | awk -F: '{print $2}' | tr -d '[[:space:]]' | grep -e "[[:digit:]]*" -ho)
      consumed_gb=$(bc <<<"scale=2; ($consumed*4096)/1024/1024/1000")
      all_consumed=$(bc <<<"scale=2; $all_consumed+$consumed_gb")
    done
    _all=$(printf "%.2f" $(bc <<<"scale=2; $all_consumed"))
    _used=$(printf "%.2f" $(bc <<<"scale=2; $installed_memory_in_gb-$all_consumed"))
    echo "$_title $(printf "%.2f" "$_used*100/$_all")%"
  else
    echo "$_title: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')"
  fi
}

function _si_disk_usage() {
  echo $(df -h | awk '$NF=="/"{printf "☉ Disk Usage: %.1f%%", $5}')
}

function _si_system_uptime() {
  echo $(uptime | awk -F'( |,|:)+' '{ if ($7=="min") m=$6; else { if ($7~/^day/) { d=$6; h=$8; m=$9} else {h=$6;m=$7}}}{print "☉ System uptime:",d+0,"days,",h+0,"hours"}')
}

function _si_current_user() {
  echo "☉ Current user: $(whoami)"
}

function _si_count_process() {
  echo "☉ Process: $(ps -e | wc -l | tr -d ' ')"
}

function _si_title() {
  if [[ $(uname) == "Darwin" ]]; then
    echo -e "Welcome to $(sw_vers -productName) ($(sw_vers -productVersion)):"
  else
    echo -e "Welcome to $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"') ($(uname -mrs)):"
  fi
}

echo -e "$(_si_title)\n"

array=("$(_si_system_load)" "$(_si_memory_usage)" "$(_si_current_user)" "$(_si_disk_usage)" "$(_si_system_uptime)" "$(_si_count_process)")
columm_num=2
row_num=$(((${#array[@]} + columm_num - 1) / columm_num))

for ((fila = 0; fila < row_num; fila++)); do
  for ((columna = 0; columna <= columm_num; columna++)); do
    indice=$((fila + row_num * columna))
    if [ $indice -eq 0 ]; then
      printf "%-0s" "${array[$indice]}"
    else
      printf "%-35s" "${array[$indice]}"
    fi
  done
  echo
done

echo
