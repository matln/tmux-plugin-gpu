#!/usr/bin/env bash

# Ref: https://github.com/samoshkin/tmux-plugin-sysstat/blob/master/scripts/cpu.sh
# Author: https://github.com/matln
# 2020/5/28

set -u
set -e

LC_NUMERIC=C

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/helpers.sh"

bar_bg_color=$(get_tmux_option "@gpu_bar_bg" "#21222C")

# Default display all gpus
if ssh_connected; then
	ssh_cmd=$(get_ssh_cmd)
	gpu_utilization=$(${ssh_cmd} "nvidia-smi -q -d UTILIZATION | grep Gpu" | awk '{print $3}')
else
	gpu_utilization=$(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}')
fi
gpu_utilization=(${gpu_utilization//\n/ })
gpu_num=${#gpu_utilization[@]}

template=''
for n in `seq 0 $(($gpu_num-1))`; do
  template=${template}"#[fg=#{color${n}}, bg=${bar_bg_color}]#{bar${n}}#[default]"
done
gpu_view_tmpl=$(get_tmux_option "@gpu_view_tmpl" "${template}")

gpu_medium_threshold=$(get_tmux_option "@gpu_medium_threshold" "10")
gpu_stress_threshold=$(get_tmux_option "@gpu_stress_threshold" "99")

# 256-color list: https://www.cnblogs.com/guochaoxxl/p/7399886.html
base_colours=(154 226 191 156 121 86 51 159)

get_bar_color(){
  local gpu_used=$1
  local color=$2

  if fcomp "$gpu_stress_threshold" "$gpu_used"; then
    echo "colour$(($color-24))";
  elif fcomp "$gpu_medium_threshold" "$gpu_used"; then
    echo "colour$(($color-12))";
  else
    echo "colour$color";
  fi
}

# 8ths 
bars=('\u2581' '\u2582' '\u2583' '\u2584' '\u2585' '\u2586' '\u2587' '\u2588')

print_gpu_used_bar() {
  local gpu_view="$gpu_view_tmpl"

  for gpu_ids in `seq 0 $(($gpu_num-1))`; do
    for n in `seq $((${#bars[@]}-1)) -1 0`; do
      if fcomp $((100 * $n / 8)) ${gpu_utilization[$gpu_ids]}; then
        local bar=${bars[$n]}
        # echo -e ${bar}
        break
      fi
    done

    local base_colour=${base_colours[$gpu_ids]}
    local colour=$(get_bar_color ${gpu_utilization[$gpu_ids]} ${base_colour})
    # echo $colour

    gpu_view="${gpu_view//"#{color${gpu_ids}}"/${colour}}"
    gpu_view="${gpu_view//"#{bar${gpu_ids}}"/${bar}}"
  done
  echo -e "$gpu_view"
}

main(){
  print_gpu_used_bar
}

main
