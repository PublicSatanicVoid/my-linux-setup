# Add default flags to some existing commands
alias btop="btop -lc"  # low-color
alias strace="loggedalias strace strace -I1 -CTfttt"  # show summaries and times
alias rg="rg --pcre2"  # more advanced regex support
alias fd="fd -u"  # unrestricted: include hidden and ignored files/folders
alias mbox='loggedalias mbox mbox -s -i -I1'
alias xterm='loggedalias xterm xterm -fa Consolas -fs 9 -bg white -fg grey10'
alias less='less -r'  # render color codes etc.

# Command overrides
alias vim='nvim'

# New aliases/shortcuts
alias gt=gnome-terminal
alias gterm=gnome-terminal
alias xt=xfce4-terminal
alias h=history
#alias ls="ls -A"
alias ll="ls -lah"

alias psshort="loggedalias psshort ps f -o pid,user,state,args -N --ppid 2"
alias pskrnl="loggedalias pskrnl ps f -o pid,fuser,state,%cpu,etime,wchan:21,args -N --ppid 2"

alias fbjobs="loggedalias fbjobs bjobs -o \"jobid user priority stat queue min_req_proc submit_time\""
alias 1="cd ../."
alias 2="cd ../../."
alias 3="cd ../../../."
alias 4="cd ../../../../."
alias x="exit"
alias rp="loggedalias rp readlink -f"
alias portusage="loggedalias portusage lsof -i -P -n"
alias lusers="who | awk '{print \$1}' | sort | uniq -c | sort -nr"
alias luser="finger"
alias cls="clear; clear"
alias servermodel="loggedalias servermodel cat /sys/devices/virtual/dmi/id/product_name"

alias vizshrc='vim ~/.zshrc; source ~/.zshrc'
