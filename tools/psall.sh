#!/bin/bash

# Prints process information in a very compact format, truncating lines to the
# terminal's width.
# 
# Key features:
# - ps prints etime in the format "days-hours:minutes:seconds" when a process has been
#   running for more than a day. But this takes up more space than just showing
#   "hours:minutes:seconds" so this script converts to that format. (There's no way to
#   specify this in ps itself)
# - Formats rss with unit suffix to reduce width and improve readability.
# - Hides kernel threads and can optionally hide system processes.
# - Uses the minimal padding between columns needed.


# Processes owned by these users are considered system processes and are skipped when
# the '-S' option is specified.
declare -A SYSTEM_USERS=(
    [root]=1
    [postfix]=1
    [nscd]=1
    [nslcd]=1
    [rpc]=1
    [polkitd]=1
    [dbus]=1
    [ntp]=1
    [rpcuser]=1
    [_rpc]=1
    [messagebus]=1
    [syslog]=1
    [Debian-snmp]=1
    [kernoops]=1
    [daemon]=1
    [rtkit]=1
    [chrony]=1
    [libstoragemgmt]=1
)


# Internally, we convert spaces in columns to Unit Separator character (0x1F)
# This way we can preserve leading spaces in the final column, the argv, so the process
# tree displays correctly.

# Unit separator character
US="\x1f"

# Output columns of ps.
# nlwp = number of threads ('num lightweight processes')
# wchan = kernel function the process is in
PS_FIELDS="pid,user:32,pcpu,nlwp,state,wchan:32,rss,etime,args"

# Sed expression to delimit ps output fields with unit separator
SED_COLS_TO_US_STRING="s/(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+) (.*)/\1$US\2$US\3$US\4$US\5$US\6$US\7$US\8$US\9/g"

exit_help() {
    echo "usage: $(basename $0) [-wkrtPEUS] [-u USER] [-s SORT_SPEC]"
    echo
    echo "  Display ps output in a more readable, compact format."
    echo
    echo "default: show pid,user,state,pcpu,etime,args"
    echo "flags:"
    echo "  -w:           wide output; show full argument list of each process"
    echo "  -k:           show kernel function names"
    echo "  -r:           show rss column"
    echo "  -t:           show number of threads per process"
    echo "  -P:           hide pcpu column"
    echo "  -E:           hide etime column"
    echo "  -U:           hide username column"
    echo "  -S:           omit system processes"
    echo "                (unless they're the parent of non-system processes)"
    echo "options:"
    echo "  -u USER:      filter to USER(s') processes"
    echo "                can specify multiple users by separating them with commas"
    echo "  -s [+-]FIELD: sort by FIELD(s) (pid,user,state,pcpu,nlwp,rss,wchan,args)"
    echo "                can specify multiple fields by separating them with commas"
    exit 1
}

# When argument is nonzero, filters stdin to remove processes owned by system users,
# unless they are the ancestor of process(es) owned by non-system users.
# Expects stdin to be the output of ps with the first two columns being pid and
# username.
filter_system_trees() {
    if [ $1 -eq 0 ]; then
        cat
        return
    fi

    local -A ppids
    local -a nonroot_pids
    while read pid ppid user <&3; do
        ppids[$pid]=$ppid
        if [ -z "${SYSTEM_USERS[$user]}" ]; then
            nonroot_pids+=( $pid )
        fi
    done 3< <(ps -eo pid,ppid,user --no-headers)

    local -A pid_has_nonroot_children
    for nonroot_pid in "${nonroot_pids[@]}"; do
        pid=$nonroot_pid
        ppid=${ppids[$pid]}
        while [ $ppid -ne 1 ]; do
            pid_has_nonroot_children[$ppid]=1
            pid=$ppid
            ppid=${ppids[$pid]}
        done
    done

    read -r header
    echo "$header"
    while read -r pid user line; do
        if [ -z "${SYSTEM_USERS[$user]}" -o ! -z "${pid_has_nonroot_children[$pid]}" ]; then
            echo "$pid $user $line"
        fi
    done
}

show_wide=0
wideflag=""
awk_maxlen="cols"
show_kfunc=0
show_rss=0
show_user=1
show_pcpu=1
show_threads=0
show_etime=1
omit_system=0

while getopts "u:s:hwkrtPEUS" o; do
    case "$o" in
        u)
            filter_user="$OPTARG"
            if [[ "$filter_user" != *","* ]]; then
                show_user=0  # if it's just one user, no need to show them
            fi
            ;;
        U)
            show_user=0
            ;;
        k)
            show_kfunc=1
            ;;
        r)
            show_rss=1
            ;;
        w)
            show_wide=1
            wideflag="www"
            awk_maxlen='length($0)'
            ;;
        t)
            show_threads=1
            ;;
        P)
            show_pcpu=0
            ;;
        E)
            show_etime=0
            ;;
        S)
            omit_system=1
            ;;
        s)
            sort_field="$OPTARG"
            ;;
        *)
            exit_help
            ;;
    esac
done

if [ ! -z "$filter_user" ]; then
    filter="-u $filter_user"
else
    # hide kernel threads
    filter="-N --ppid 2"
fi
if [ ! -z "$sort_field" ]; then
    bsd="k$sort_field"
else
    bsd="f"
fi

ps $bsd $wideflag $filter -o "$PS_FIELDS" \
| filter_system_trees $omit_system \
| sed -r "$SED_COLS_TO_US_STRING" \
| awk \
    -v show_kfunc=$show_kfunc \
    -v show_rss=$show_rss \
    -v show_user=$show_user \
    -v show_pcpu=$show_pcpu \
    -v show_threads=$show_threads \
    -v show_etime=$show_etime \
    -v show_wide=$show_wide \
    -F"$(echo -e $US)" \
'
BEGIN { rowcount = 0 }

# Exclude kthreadd
{ include_row = $1 != 2 }

# Spool up output rows so they can be printed with proper width at the end
include_row {
    # The whole command string is treated as one column even though it
    # could contain spaces

    rowcount += 1

    pids[rowcount] = $1
    users[rowcount] = $2
    pcpus[rowcount] = $3
    threads[rowcount] = $4
    states[rowcount] = $5
    wchans[rowcount] = $6
    rss[rowcount] = $7
    etimes[rowcount] = $8
    argvs[rowcount] = $9
}


NR==1 { 
    $3 = "CPU"  # replace "%CPU" with just "CPU"

    pcpus[1] = "CPU"

    maxlen_pid = length($1)
    maxlen_user = length($2)
    maxlen_pcpu = length($3)
    maxlen_threads = length($4)
    maxlen_state = length($5)
    maxlen_wchan = length($6)
    maxlen_rss = length($7)
    maxlen_etime = length($8)
}


NR>1 && include_row {

    # Abbreviate user like ps would, unless they specified wide output
    user = $2
    if (!show_wide) {
        if (length($2) > 8) {
            user = substr($2, 0, 7)"+"
            users[rowcount] = user
        }
    }

    # Make rss more compact by adding suffixes
    rss_num = $7

    rss_str = ""
    if (rss_num > 1024 * 1024 * 1024) {
        rss_str = sprintf("%.03fT", (rss_num/1024/1024/1024))
    }
    else if (rss_num > 1024 * 1024) {
        rss_str = sprintf("%.03fG", (rss_num/1024/1024))
    }
    else if (rss_num > 1024) {
        rss_str = sprintf("%.03fM", (rss_num/1024))
    }
    else {
        rss_str = sprintf("%.03fK", rss_num)
    }
    rss[rowcount] = rss_str
    
    # Make etime more compact by converting days-hours:minutes:seconds
    # to just hours:minutes:seconds
    etime = $8

    split(etime, days_hms, "-")
    
    if (length(days_hms) > 1) {
        days = days_hms[1] + 0
        hms = days_hms[2]

        split(hms, h_m_s, ":")

        if (length(h_m_s) == 3) {

            hours = h_m_s[1] + 0
            minutes = h_m_s[2] + 0
            seconds = h_m_s[3] + 0

            tot_hours = hours + (24 * days)

            etime = sprintf("%d:%02d:%02d", tot_hours, minutes, seconds)
            #etime = tot_hours ":" minutes ":" seconds
            etimes[rowcount] = etime
        }
    }

    # Update column widths
    if (length($1) > maxlen_pid) { maxlen_pid = length($1) }
    if (length(user) > maxlen_user) { maxlen_user = length(user) }
    if (length($3) > maxlen_pcpu) { maxlen_pcpu = length($3) }
    if (length($4) > maxlen_threads) { maxlen_threads = length($4) }
    if (length($5) > maxlen_state) { maxlen_state = length($5) }
    if (length($6) > maxlen_wchan) { maxlen_wchan = length($6) }
    if (length(rss_str) > maxlen_rss) { maxlen_rss = length(rss_str) }
    if (length(etime) > maxlen_etime) { maxlen_etime = length(etime) }
}

END {
    # Print all rows with correct widths
    fmt1 = "%"maxlen_pid"s"

    if (show_user) {
        fmt2 = " %-"maxlen_user"s"
    }

    if (show_pcpu) {
        fmt3 = " %"maxlen_pcpu"s"
    }

    if (show_threads) {
        fmt4 = " %"maxlen_threads"s"
    }

    fmt5 = " %-"maxlen_state"s"

    if (show_kfunc) {
        fmt6 = " %"maxlen_wchan"s"
    }
    if (show_rss) {
        fmt7 = " %"maxlen_rss"s"
    }

    if (show_etime) {
        fmt8 = " %"maxlen_etime"s"
    }

    fmt9 = " %s\n"
    #fmt = "%"maxlen_pid"s %-"maxlen_user"s %"maxlen_pcpu"s %-"maxlen_state"s %"maxlen_etime"s %s\n"

    for (i = 1; i <= rowcount; i++) {
        printf fmt1, pids[i]
        if (show_user) {
            printf fmt2, users[i]
        }
        if (show_pcpu) {
            printf fmt3, pcpus[i]
        }
        if (show_threads) {
            printf fmt4, threads[i]
        }
        printf fmt5, states[i]
        if (show_kfunc) {
            printf fmt6, wchans[i]
        }
        if (show_rss) {
            printf fmt7, rss[i]
        }
        if (show_etime) {
            printf fmt8, etimes[i]
        }
        printf fmt9, argvs[i]
        #printf fmt, pids[i], users[i], pcpus[i], states[i], etimes[i], argvs[i]
    }
}
' \
| awk "BEGIN { cols=$(tput cols) }   { print substr(\$0, 1, $awk_maxlen) }"
