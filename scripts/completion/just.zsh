# Source this file after compinit to enable ShmerV's Just completions.
typeset -g _shmerv_completion_root=${${(%):-%x}:A:h:h:h}

_shmerv_just() {
  local root=$PWD recipe=${words[2]} item line
  local -a candidates

  # Only apply project-specific argument completion to this checkout.
  while [[ $root != / && ! -f $root/justfile ]]; do
    root=${root:h}
  done
  if [[ $root != $_shmerv_completion_root ]]; then
    if autoload -Uz +X _just 2>/dev/null; then
      _just
    else
      _files
    fi
    return
  fi

  if (( CURRENT == 2 )); then
    # Read recipe declarations; never execute recipes or Just substitutions.
    while IFS= read -r line; do
      if [[ $line =~ '^([[:alnum:]_-]+)([[:space:]].*)?:$' ]]; then
        candidates+=($match[1])
      fi
    done < "$root/justfile"
  else
    case $recipe in
      test|sim|wave)
        if (( CURRENT == 3 )); then
          for item in "$root"/tb/**/*_tb.sv(N); do
            candidates+=(${${item:t}%_tb.sv})
          done
        elif (( CURRENT == 4 )) && [[ ${words[3]} == cpu_system ]]; then
          for item in "$root"/tb/cpu/programs/*(/N); do
            [[ -f $item/${item:t}.c || -f $item/${item:t}.S ]] && candidates+=(${item:t})
          done
          [[ $recipe == test ]] && candidates+=(-l --list)
        elif (( CURRENT == 5 )) && [[ $recipe == sim && ${words[3]} == cpu_system ]]; then
          candidates+=(--elf)
        fi
        ;;
      fpga-list)
        (( CURRENT == 3 )) && candidates+=(targets programs images all)
        ;;
      firmware-build|fpga-build|fpga-repack|fpga-flash)
        if (( CURRENT == 3 )) && [[ $recipe != firmware-build ]]; then
          for item in "$root"/fpga/tang_nano_9k/*/sources.f(N); do
            candidates+=(${item:h:t})
          done
        elif { (( CURRENT == 3 )) && [[ $recipe == firmware-build ]]; } \
          || { (( CURRENT == 4 )) && [[ ${words[3]} == cpu_system ]]; }; then
          if [[ $recipe == fpga-flash ]]; then
            for item in "$root"/build/fpga/tang_nano_9k/cpu_system/images/*.fs(N); do
              candidates+=(${item:t:r})
            done
          else
            for item in "$root"/sw/programs/*(/N); do
              [[ -f $item/main.c || -f $item/main.S ]] && candidates+=(${item:t})
            done
          fi
        elif [[ $recipe == fpga-flash ]]; then
          if { (( CURRENT == 4 )) && [[ ${words[3]} != cpu_system ]]; } \
            || { (( CURRENT == 5 )) && [[ ${words[3]} == cpu_system ]]; }; then
            candidates+=(sram flash)
          fi
        fi
        ;;
    esac
  fi

  if (( ${#candidates} )); then
    compadd -- ${(u)candidates}
    # Show choices on the first Tab, even when a common prefix was inserted.
    compstate[list]=list
  fi
}

if (( ! $+functions[compdef] )); then
  autoload -Uz compinit
  compinit
fi
compdef _shmerv_just just
