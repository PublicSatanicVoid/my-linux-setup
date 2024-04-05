function loggedcmd {
    # Only log if stdout is a terminal
    if [ -t 1 ]; then
        echo -e "\033[0;1m$\033[0m $@"
        cmd="$(whence "$1")"
        # Adapted from https://stackoverflow.com/a/8723305
        C="$cmd"
        for i in "${@:2}"; do
            if [ "$i" = "|" ]; then
                C="$C |"
            else
                i="${i//\\/\\\\}"
                i="${i//\$/\\\$}"
                C="$C \"${i//\"/\\\"}\""
            fi
        done
    fi
    sh -c "$C"
    exitcode=$?
    return $exitcode
}

function loggedalias {
    if [ -t 1 ]; then
        echo -ne "\033[0;1malias: "
    fi
    loggedcmd "${@:2}"
}

function pysearch {
    (set -x;
        rg -tpy \
        -g'!*__pycache__*' \
        -g'!*junk*' \
        -g'!.*' \
        "^[^#]*$1" "${@:2}"
    )
}

function ps-topmem {
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
}

function ps-topcpu {
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head
}

function cleanbash {
    # Opens a Bash subshell in a clean environment.
    /usr/bin/env -i TERM=$TERM PS1='\[\033[0m\033[1m\]\u@\h:\[\033[0m\] ' /bin/bash --login --noprofile --norc 
}

function cleanzsh {
    /usr/bin/env -i \
        TERM=$TERM SHELL=$SHELL \
        PS1='%m{%n}%2~: ' \
        PATH='/usr/local/bin:/usr/bin:/bin' \
        LOGNAME=$LOGNAME USER=$USER \
        /bin/zsh --no-rcs --PROMPT_SUBST
}

function tar_and_remove {
    loggedcmd \
        tar -cf $1.tar.bz2 -Ipbzip2 $1 --remove-files
}
function xz_and_remove {
    XZ_OPT="-T0 -9" \
    loggedcmd \
        tar -cJf $1.tar.xz $1 --remove-files
}

function replace_all {
    if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
        echo "replace_all <path> <search-string> <replace-string>"
        return
    fi
    loggedcmd \
        find "$1" -type f -exec sed -i -e "s/$2/$3/g" {} \;
}

# Give `git` more permissive defaults - prevents accidentally breaking permissions on
# shared remotes
function git {
    (umask 0002; command git "$@")
}

function vimwich {
    nvim `which "$1"`
}

function mkcd {
    loggedcmd \
        mkdir -p "$1"
    loggedcmd \
        cd "$1"  # Can't actually cd
    cd "$1"
}

function dup {
    real_cwd="$(readlink -e "$(pwd)")"
    real_cwd_parent="$(readlink -e "$(dirname "$real_cwd")")"

    cwd_basename="$(basename "$real_cwd")"

    dest="${1:-dup.${cwd_basename}}"

    loggedcmd \
        cd "$real_cwd_parent"
    cd "$real_cwd_parent"

    loggedcmd \
        zcp "$real_cwd" "$dest"

    loggedcmd \
        cd "$dest"
    cd "$dest"
}

function cdls {
    cd "$1"
    loggedcmd \
        cd "$1" && ls
}

function realcwd {
    echo "$(readlink -f "$(pwd)")"
}

function pyinit {
    mkdir -p "$1"
    touch "$1"/__init__.py
}


