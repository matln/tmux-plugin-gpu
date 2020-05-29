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
# nvidia-smi -q -d MEMORY | grep Used | awk 'NR%2==1{print $3}'
gpu_utilization=$(nvidia-smi -q -d UTILIZATION | grep Gpu | awk '{print $3}')
gpu_utilization=(${gpu_utilization//\n/ })
gpu_num=${#gpu_utilization[@]}
template=''
for n in `seq 0 $(($gpu_num-1))`; do
  template=${template}"#[fg=#{color${n}}, bg=${bar_bg_color}]#{bar${n}}#[default]"
done
gpu_view_tmpl=$(get_tmux_option "@gpu_view_tmpl" "${template}")

gpu_medium_threshold=$(get_tmux_option "@gpu_medium_threshold" "10")
gpu_stress_threshold=$(get_tmux_option "@gpu_stress_threshold" "99")

# #00ff00: lime, #ffff00: yellow, #ff0000: red
bar_color_low=$(get_tmux_option "@gpu_color_low" "#00ff00")
bar_color_medium=$(get_tmux_option "@gpu_color_medium" "#ffff00")
bar_color_stress=$(get_tmux_option "@gpu_color_stress" "#ff0000")

get_bar_color(){
  local gpu_used=$1

  if fcomp "$gpu_stress_threshold" "$gpu_used"; then
    echo "$bar_color_stress";
  elif fcomp "$gpu_medium_threshold" "$gpu_used"; then
    echo "$bar_color_medium";
  else
    echo "$bar_color_low";
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

    local colour=$(get_bar_color ${gpu_utilization[$gpu_ids]})
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
