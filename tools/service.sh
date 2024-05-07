#!/bin/sh

CMD="$(basename "$0")"

KILL_WAIT_INT_S=5
KILL_POLL_INT_S=1

function handle_sig() {
    logfile=$1
    pid=$2
    if ps -p $pid >/dev/null; then
        statusmsg="PID $pid is still running."
    else
        statusmsg="PID $pid is NOT running."
    fi
    echo "Supervisor process was signaled at $(date +%s). $statusmsg" >> $logfile
}

function exit_help() {
    echo "A simple, configuration-less, unprivileged service manager."
    echo
    echo "usage: $CMD start -r STATUSFILE -l LOGFILE -s SIGNALFILE -- CMD [ARGS...]"
    echo "  Runs CMD in the background and repeatedly reruns it if it fails."
    echo "  Ensures there is only one running CMD per STATUSFILE."
    echo "  STATUSFILE and LOGFILE will be created when CMD is started."
    echo "  SIGNALFILE will only be created during a '$CMD stop|wait-stop'."
    echo
    echo "usage: $CMD status STATUSFILE"
    echo "  Checks the status of the service with STATUSFILE."
    echo
    echo "usage: $CMD stop STATUSFILE"
    echo "  Attempts to stop the service with STATUSFILE and waits for it to exit."
    echo
    echo "usage: $CMD wait-stop STATUSFILE"
    echo "  Prevents the service with STATUSFILE from being restarted, and waits for it"
    echo "  to exit. Does not attempt to stop the service."
    echo "  If the service is started again ('$CMD start') the normal restart"
    echo "  behavior will resume."
    exit 1
}

SUBCMD="${1:-help}"
shift 1

if [ "$SUBCMD" == "help" ]; then
    exit_help
elif [ "$SUBCMD" == "runloop" ]; then
    while getopts "r:l:s:" o; do
        case "$o" in
            r) statusfile="$OPTARG";;
            l) logfile="$OPTARG";;
            s) signalfile="$OPTARG";;
            *) exit_help;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [[ -z "$statusfile" || -z "$logfile" || -z "$signalfile" ]]; then
        exit_help
    fi

    while true; do
        if [ -f $signalfile ]; then
            echo "Signal file $signalfile exists; exiting..." >> $logfile
            rm $signalfile
            rm $statusfile
            exit
        fi

        nohup setsid "$@" </dev/null 1>/dev/null 2>/dev/null &
        pid=$!
        host=$(hostname -f)
        user=$(id -un)
        ts=$(date +%s)

        trap "handle_sig $logfile $pid" SIGHUP SIGINT SIGQUIT SIGUSR1 SIGUSR2 SIGPIPE SIGCONT SIGSTOP SIGTSTP

        echo "$pid $host $user $ts $(readlink -f $signalfile) $(readlink -f $logfile)" >| $statusfile
        echo "Started on $host by $user at $ts with PID $pid, waiting for exit..." >> $logfile
        wait
        status=$?
        echo "...exited with status $status" >> $logfile
    done
elif [ "$SUBCMD" == "start" ]; then
    while getopts "r:l:s:" o; do
        case "$o" in
            r) statusfile="$OPTARG";;
            l) logfile="$OPTARG";;
            s) signalfile="$OPTARG";;
            *) exit_help;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [[ -z "$statusfile" || -z "$logfile" || -z "$signalfile" ]]; then
        exit_help
    fi

    if [ -f $statusfile ]; then
        echo "Service is already running (statusfile exists: $statusfile)"
        echo "Do '$CMD status $statusfile' for more information"
        exit 1
    fi
    nohup setsid \
        "$0" runloop \
        -r "$statusfile" \
        -l "$logfile" \
        -s "$signalfile" \
        "$@" \
        </dev/null 1>/dev/null 2>/dev/null &
elif [ "$SUBCMD" == "status" ]; then
    statusfile=$1
    if [ ! -f $statusfile ]; then
        echo "Service does not appear to be running"
        exit 1
    fi
    read svc_pid svc_host svc_user svc_ts svc_signalfile svc_logfile < $statusfile
    if [ $svc_host == $(hostname -f) ]; then
        if ps -p $svc_pid >/dev/null 2>&1 ; then
            echo "UP"
        else
            echo "DOWN: Stale status file '$statusfile'"
        fi
    else
        echo "Cannot check current status (must run from host $svc_host)"
    fi

    echo "Last status info"
    echo "----------------"
    echo "PID:              $svc_pid"
    echo "Host:             $svc_host"
    echo "User:             $svc_user"
    echo "Started:          $svc_ts"
    if [ -f $svc_signalfile ]; then
        signal_status=" (signaled)"
    else
        signal_status=" (not signaled)"
    fi
    echo "Signal file:      $svc_signalfile$signal_status"
    echo "Log file:         $svc_logfile"
    (set -x; tail -2 $svc_logfile)
elif [ "$SUBCMD" == "stop" ]; then
    statusfile=$1
    if [ ! -f $statusfile ]; then
        echo "Service does not appear to be running"
        exit 1
    fi
    read svc_pid svc_host svc_user svc_ts svc_signalfile svc_logfile < $statusfile
    if [ $svc_host != $(hostname -f) ]; then
        echo "Can only stop the service from the host it is running on: $svc_host"
        exit 1
    elif [ $svc_user != $(id -un) -a $(id -un) != "root" ]; then
        echo "Can only stop the service as the user it is running as ($svc_user) or root"
        exit 1
    fi
    touch $svc_signalfile
    /usr/bin/kill -SIGINT $svc_pid
    echo "Sent SIGINT to PID $svc_pid"
    if ps -p $svc_pid >/dev/null; then
        sleep $KILL_WAIT_INT_S
        if ps -p $svc_pid >/dev/null; then
            /usr/bin/kill -SIGTERM $svc_pid
            echo "Sent SIGTERM to PID $svc_pid"
            if ps -p $svc_pid >/dev/null; then
                sleep $KILL_WAIT_INT_S
                /usr/bin/kill -SIGKILL $svc_pid
                echo "Sent SIGKILL to PID $svc_pid"
                sleep $KILL_WAIT_INT_S
                if ps -p $svc_pid >/dev/null; then
                    echo "Failed to stop the service"
                fi
            fi
        fi
    fi
    rm -f $svc_signalfile
    rm -f $svc_statusfile
elif [ $SUBCMD == "wait-stop" ]; then
    statusfile=$1
    if [ ! -f $statusfile ]; then
        echo "Service does not appear to be running"
        exit 1
    fi
    read svc_pid svc_host svc_user svc_ts svc_signalfile svc_logfile < $statusfile
    if [ -f $svc_signalfile ]; then
        echo "Service is already waiting to stop"
        exit 1
    fi
    touch $svc_signalfile
    if [ $? -ne 0 ]; then
        echo "Failed to create signal file. Service will not be stopped."
        exit 1
    fi
    echo "Service will no longer be restarted. Waiting for service to stop..."
    if [ $(hostname -f) == $svc_host ]; then
        while ps -p $svc_pid >/dev/null; do
            sleep $KILL_POLL_INT_S
        done
        echo "Service stopped (PID $svc_pid no longer exists)"
    fi
    while [ -f $statusfile ]; do
        sleep $KILL_WAIT_INT_S
    done
    echo "Service stopped (statusfile $statusfile was removed)"
else
    exit_help
fi
