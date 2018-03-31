# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    # shellcheck disable=SC1091
    . /etc/bashrc
fi
if [ -f /etc/profile ]; then
    # shellcheck disable=SC1091
    . /etc/profile
fi

# Contain all functions in a parent function for manageability
function __bashrc() {
    # Save hostname for prompt colouring on remote machines,
    # and limiting some functions to the home machine.
    export __hostname=${__hostname:-${HOSTNAME}}

    if [[ ${HOSTNAME} == "${__hostname}" && ${USER} != "root" ]]; then
        __local_functions
    fi

    # Ensure Tilix works properly with custom PROMPT_COMMAND
    # https://gnunn1.github.io/tilix-web/manual/vteconfig/
    if [[ $TILIX_ID ]] || [[ $VTE_VERSION ]] && [[ -f /etc/profile.d/vte.sh ]]; then
        # Must be sourced outside PROMPT_COMMAND function
        # shellcheck disable=SC1091
        source /etc/profile.d/vte.sh
    fi

    PROMPT_COMMAND=__set_prompt

    # Smarter search, press up after typing
    bind '"\e[A"':history-search-backward
    bind '"\e[B"':history-search-forward

    # Switch to another user while retaining settings
    function sush() {
        __pack

        local user=${1:-"root"}

        sudo -u "${user}" -i                  \
            __bashrc_file="${__bashrc_file}"  \
            __vimrc_file="${__vimrc_file}"    \
            __hostname="${__hostname}"        \
            bash -c "exec bash --init-file <(echo \${__bashrc_file} | base64 --decode | xz -d)"
    }

    # The same idea as sush, but with SSH
    function rush() {
        __pack

        # shellcheck disable=SC2029
        ssh -t "$@" " \
        __bashrc_file=${__bashrc_file}      \
        __vimrc_file=${__vimrc_file}        \
        __hostname=${__hostname}            \
        bash --init-file <(echo ${__bashrc_file} | base64 --decode | xz -d)
        "
    }

    # This time, vim!
    function suvi() {
        vim -S <(echo "${__vimrc_file}" | base64 --decode | xz -d) "${@}"
    }

    # Enable bash completion for custom functions
    if [[ $( type -t _completion_loader ) ]]; then
        _completion_loader ssh
        complete -F _ssh rush
    fi

    __set_aliases

    # Nice ls colors
    eval "$(dircolors)"

    # Enable globstar recursive pattern (ls **/*.sh)
    shopt -s globstar

    # History settings
    HISTCONTROL="erasedups:ignoreboth"
    HISTFILESIZE=9999
    HISTSIZE=9999
    shopt -s histappend
}

function __local_functions() {
    if command -v rustc >/dev/null; then
        # Rust dev stuff
        export PATH=$HOME/.cargo/bin:${PATH}
        # shellcheck disable=SC2155
        export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
        # shellcheck disable=SC2155
        export LD_LIBRARY_PATH="$(rustc --print sysroot)/lib:$LD_LIBRARY_PATH"
    fi

    export GOPATH="${HOME}/go"
    export EDITOR=vim
    export ANSIBLE_NOCOWS=1

    if [[ -d ~/.completion ]]; then
        # shellcheck disable=SC1090
        source ~/.completion/*
    fi
}

# Save various things to variables
function __pack() {
    # Store rc files in base64 for transport
    __bashrc_file=${__bashrc_file:-"$(xz -zc ~/.bashrc | base64 -w 0)"}
    __vimrc_file=${__vimrc_file:-"$(xz -zc ~/.vimrc | base64 -w 0)"}
}

function maybe() {
    local rng=$(( RANDOM %2 ))
    if [[ ! -z $1 ]]; then
        [[ ${rng} -eq 0 ]] || "$@"
    else
        return ${rng}
    fi
}

# Set some aliases
function __set_aliases {
    # Make sudo respect aliases
    alias sudo='sudo '
    alias fuck='sudo $(history -p \!\!)'
    alias please='fuck'
}

# Prompt magic
function __set_prompt {
    # Has to be defined at the top in order to properly capture
    # the exit code of the last command executed in the shell.
    local -r exitcode="$?"

    # Define colors and stuff for convenience
    local -r r="\\e[31m"    # Red
    local -r g="\\e[32m"    # Green
    local -r y="\\e[33m"    # Yellow
    local -r b="\\e[34m"    # Blue

    local -r d="\\e[1m"     # Bold
    local -r o="\\e[0m"     # Reset

    local ps_time="${y}\\t${o}"
    local ps_user
    local ps_dir="${o}\\w${o}"
    local ps_exit
    local ps_sign
    local ps_git
    local -r ps_git_sh="/usr/share/git-core/contrib/completion/git-prompt.sh"

    #local ps0=
    local ps1
    local ps2

    # User and host information.
    # If root, always turn red.
    # If on your own computer, turn blue.
    # If on another computer, turn green.
    ps_user="\\u @ \\h"

    if [[ ${UID} -eq 0 ]]; then
        ps_user="${d}${r}${ps_user}${o}"
        ps_sign="#"
    else
        if [[ ${HOSTNAME} == "${__hostname}" ]]; then
            ps_user="${d}${b}${ps_user}${o}"
        else
            ps_user="${d}${g}${ps_user}${o}"
        fi
        ps_sign="$"
    fi

    # Trim the path if more than two directories deep.
    PROMPT_DIRTRIM=2

    # Display exit code information.
    if [[ ${exitcode} -eq 0 ]]; then
        ps_exit="${d}${g}>${o}"
    else
        ps_exit="${r}(${exitcode}) ${d}${r}>${o}"
    fi

    # Show the current branch in the prompt
    # when current working directory is a git repository.
    if [[ -f ${ps_git_sh} ]]; then
        # shellcheck source=/dev/null
        source ${ps_git_sh}
        ps_git=$(__git_ps1 "${d}${y}%s${o} | ")
    fi

    # Ensure Tilix works properly with custom PROMPT_COMMAND.
    # https://gnunn1.github.io/tilix-web/manual/vteconfig/
    if [[ $TILIX_ID ]] || [[ $VTE_VERSION ]] && [[ -f /etc/profile.d/vte.sh ]]; then
        ps_vte="$(__vte_prompt_command)"
    fi

    # Build prompt and mark all \[non-printing characters\],
    # so that Bash does not get confused about the length of a line.
    # ${ps_vte} needs to be placed before any newlines,
    # or it will trigger notifications during window resizes.
    ps1="${o}\\[${ps_vte}\\]\\[${ps_time} ) ${ps_user} | ${ps_dir} | ${ps_git}${ps_exit}\\]\\r\\n${ps_sign} "
    ps2="> "

    PS1="${ps1}"
    PS2="${ps2}"

    # Output a newline before and after every command
    trap echo DEBUG
}

__bashrc
