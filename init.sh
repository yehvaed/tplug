#!/usr/bin/env bash
# vim :filetype=bash

export CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export XDG_DATA_HOME="${XDG_DATA_HOME-${HOME}/.local/share}/tmux"

# ==> libs
log() {
	tmux display-message -d 1000 ${DEBUG_OPT} "$@"
}

sources:github:clone() {
  git clone https://github.com/${1}.git ${2} > /dev/null
}

sources:github:update() {
  (cd ${$2} && git pull)
}

try_option() {
  tmux show -gv "$1" 2> /dev/null || echo "$2"
}

# ==> main
config_file=$(try_option "@tpm-config-file" "${HOME}/.tmux.conf")
default_client=$(try_option "@tpm-default-client" "github")
client=${default_client}

while read line; do 
  case ${line} in
    # we not need comments 
    ("#"*) continue;;

    # directive to add plugin
    (*@plugin*) 
        line=$(echo ${line} | sed -E 's/^.+@plugin *//g' | tr -d '"' | tr -d "'")
        plugin_name=$(echo "$line")
    ;;
  esac

  # if we approach plugin directive it means end here and process
  if [[ -n "${plugin_name}" ]]; then 
    plugin_dir="${XDG_DATA_HOME}/${plugin_name//\//---}"
    
    if [[ ! -d "${plugin_dir}" ]]; then
      log " cloning ${plugin_name}..."
      sources:${client}:clone ${plugin_name} ${plugin_dir}
    fi

    if [[ -n "${update}" ]]; then
      log " updating ${plugin_name}..."
      sources:${client}:update ${plugin_name} ${plugin_dir}
    fi
    
    bash ${plugin_dir}/*.tmux
    unset plugin_name
  fi


done < ${config_file}
