#!/bin/bash

# Prints process information in a very compact format, truncating lines to the terminal's width.
# ps prints etime in the format "days-hours:minutes:seconds" when a process has been running for
# more than a day. But this takes up more space than just showing "hours:minutes:seconds" so this
# script converts to that format. (There's no way to specify this in ps itself)
# Also this uses the minimal padding between columns needed

# Converts spaces in columns to Unit Separator character (0x1F)
# This way we can preserve leading spaces in the final column, the argv, so the process tree
# displays correctly.
#


exit_help() {
    echo "usage: $(basename $0) [-k] [-r] [-w] [-u USER | -un]"
    echo "options:"
    echo "  -k:      show kernel function names"
    echo "  -r:      show rss column"
    echo "  -w:      wide output; show full argument list of each process"
    echo "  -un:     hide username column"
    echo "  -u USER: filter to USER and hide username column"
    exit 1
}

wideflag=""
awk_maxlen="cols"
show_kfunc=0
show_rss=0
show_user=1

while getopts "u:hkrw" o; do
    case "$o" in
        u)
            if [[ "$OPTARG" == "n" ]]; then
                show_user=0
            else
                filter_user="$OPTARG"
                show_user=0  # if it's just one user, no need to show them
            fi
            ;;
        k)
            show_kfunc=1
            ;;
        r)
            show_rss=1
            ;;
        w)
            wideflag="www"
            awk_maxlen='length($0)'
            ;;
        *)
            exit_help
            ;;
    esac
done

US="\x1f"

SED_COLS_TO_RS_STRING="s/(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+)[ ]+(\S+) (.*)/\1$US\2$US\3$US\4$US\5$US\6$US\7$US\8/g"

if [ ! -z "$filter_user" ]; then
    filter="-u $filter_user"
else
    # hide kernel threads
    filter="-N --ppid 2"
fi

PS_OUTPUT=$(ps f$wideflag $filter -o pid,user,pcpu,state,wchan:32,rss,etime,args)
PS_OUTPUT=$(sed -r "$SED_COLS_TO_RS_STRING" <<< "$PS_OUTPUT")


awk \
    -v show_kfunc=$show_kfunc \
    -v show_rss=$show_rss \
    -v show_user=$show_user \
    -F"$(echo -e $US)" \
'

# Spool up output rows so they can be printed with proper width at the end
{
    # The whole command string is treated as one column even though it
    # could contain spaces

    pids[NR] = $1
    users[NR] = $2
    pcpus[NR] = $3
    states[NR] = $4
    wchans[NR] = $5
    rss[NR] = $6
    etimes[NR] = $7
    argvs[NR] = $8
}


NR==1 { 
    $3 = "CPU"  # replace "%CPU" with just "CPU"

    pcpus[1] = "CPU"

    maxlen_pid = length($1)
    maxlen_user = length($2)
    maxlen_pcpu = length($3)
    maxlen_state = length($4)
    maxlen_wchan = length($5)
    maxlen_rss = length($6)
    maxlen_etime = length($7)
}


NR>1 {

    # Make rss more compact by adding suffixes
    rss_num = $6

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
    rss[NR] = rss_str
    
    # Make etime more compact by converting days-hours:minutes:seconds
    # to just hours:minutes:seconds
    etime = $7

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

            etime = tot_hours ":" minutes ":" seconds
            etimes[NR] = etime
        }
    }

    # Update column widths
    if (length($1) > maxlen_pid) { maxlen_pid = length($1) }
    if (length($2) > maxlen_user) { maxlen_user = length($2) }
    if (length($3) > maxlen_pcpu) { maxlen_pcpu = length($3) }
    if (length($4) > maxlen_state) { maxlen_state = length($4) }
    if (length($5) > maxlen_wchan) { maxlen_wchan = length($5) }
    if (length(rss_str) > maxlen_rss) { maxlen_rss = length(rss_str) }
    if (length(etime) > maxlen_etime) { maxlen_etime = length(etime) }
}

END {
    # Print all rows with correct widths
    fmt1 = "%"maxlen_pid"s"

    if (show_user) {
        fmt2 = " %-"maxlen_user"s"
    }

    fmt3 = " %"maxlen_pcpu"s %-"maxlen_state"s"

    if (show_kfunc) {
        fmt4 = " %"maxlen_wchan"s"
    }
    if (show_rss) {
        fmt5 = " %"maxlen_rss"s"
    }

    fmt6 = " %"maxlen_etime"s %s\n"
    #fmt = "%"maxlen_pid"s %-"maxlen_user"s %"maxlen_pcpu"s %-"maxlen_state"s %"maxlen_etime"s %s\n"

    for (i = 1; i <= NR; i++) {
        printf fmt1, pids[i]
        if (show_user) {
            printf fmt2, users[i]
        }
        printf fmt3, pcpus[i], states[i]
        if (show_kfunc) {
            printf fmt4, wchans[i]
        }
        if (show_rss) {
            printf fmt5, rss[i]
        }
        printf fmt6, etimes[i], argvs[i]
        #printf fmt, pids[i], users[i], pcpus[i], states[i], etimes[i], argvs[i]
    }
}
' <<< "$PS_OUTPUT" | awk "BEGIN { cols=$(tput cols) }   { print substr(\$0, 1, $awk_maxlen) }"

