# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# User specific aliases and functions

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# Completion options
#
# Define to access remotely checked-out files over passwordless ssh for CVS
# COMP_CVS_REMOTE=1
#
# Define to avoid stripping description in --option=description of './configure --help'
# COMP_CONFIGURE_HINTS=1
#
# Define to avoid flattening internal contents of tar files
# COMP_TAR_INTERNAL_PATHS=1
#
# Uncomment to turn on programmable completion enhancements.
# Any completions you add in ~/.bash_completion are sourced last.
#[[ -f /etc/bash_completion ]] && . /etc/bash_completion

# History Options
# Don't put duplicate lines in the history.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export PYTHONSTARTUP=~/.startup.py
# Aliases
alias grep='grep --color'
alias egrep='egrep --color=auto'
#alias zegrep='zegrep --color=auto'

#alias ls='ls -AhF --color=tty'
alias ll='ls -lAhF --color=tty'
alias ltr='ls -ltrAhF --color=tty'

alias vi='vim'
alias logs='cd /integral/logs && ltr'

alias cdwin='cd /cygdrive/c/Users/fabio.ghirardello/'
alias g='echo "SSH into gateway" && ssh ghirardellof@65.219.151.125 -p 2222'
alias g2='echo "SSH into gateway 64.74.252.11" && ssh ghirardellof@64.74.252.11 -p 2222'
alias gg='echo "SFTP into gateway" && sftp -P 2222 ghirardellof@65.219.151.125'
alias kst='kill `cat Stunnel.pid`'
alias ts='date -u "+%Y-%m-%d %H:%M:%S"'
alias m='mysql -u root -p tickets'


# Functions
function curly { echo -n `ts` "  "; curl "$@"; echo;}
function tt { tail -f $@ | tr \\001 \|; }
function pprint { cat $@ | sed 's/,/ ,/g' | column -t -s, ;}
function gr {
        REGEX="";
        LOGS="";
        ISFIRST="1";
        for var in $@; do
                if [ $(echo ${var:0:1}) = "-" ] ; then
                        REGEX=$(echo $REGEX " " $var);
                else
                        if [ $(echo $ISFIRST) = "1" ] ; then
                                REGEX=`echo $REGEX " " $var`;
                                ISFIRST="0";
                        else LOGS=`echo $LOGS " " $var`;
                        fi
                fi
        done;
        zegrep --color=auto ".*" $LOGS | tr \\001 \| | zegrep --color=auto $REGEX;
}

function jmx {
        # param 1 is the uat/prod server + internal port as per data/apps.html
        echo "Starting Tunnel from localhost:7777 to $1";
        echo "-------------------------------------------------------" ;
        ssh -L 7777:$1 ghirardellof@65.219.151.125 -p 2222;
}

function stp {
    # find the line number of the last match only
    Q=`zegrep -n "$1" "$2" | tail -n1 | cut -d":" -f1`;

    # exit if nothing is found
    if [ -z `echo $Q` ] ; then
        return 0;
    fi

    # determine if the file is a .gz file
    F=`file -b "$2" | cut -d" " -f1`;

    # find how many rows the message is long
    if [ $F == "gzip" ] ; then
        E=`zcat "$2" | sed  "1,$Q d" | zegrep -n "</workflowMessage>" | head -n1 | cut -d":" -f1`;
    else
        E=`sed  "1,$Q d" "$2" | zegrep -n "</workflowMessage>" | head -n1 | cut -d":" -f1`;
    fi

    # find the line number of the last row of the stp message
    W=$((Q + E));

    # extract only the lines related to the stp message
    if [ $F == "gzip" ] ; then
        zcat "$2" | sed -n "$Q,$W p" | tr -d "\n";
    else
        sed -n "$Q,$W p" "$2" | tr -d "\n";
    fi

    # add a line return
    echo
}

# Prompt and prompt colors
# 30m - Black
# 31m - Red
# 32m - Green
# 33m - Yellow
# 34m - Blue
# 35m - Purple
# 36m - Cyan
# 37m - White
# 0 - Normal
# 1 - Bold
function prompt {
  local BLACK="\[\033[0;30m\]"
  local BLACKBOLD="\[\033[1;30m\]"
  local RED="\[\033[0;31m\]"
  local REDBOLD="\[\033[1;31m\]"
  local GREEN="\[\033[0;32m\]"
  local GREENBOLD="\[\033[1;32m\]"
  local YELLOW="\[\033[0;33m\]"
  local YELLOWBOLD="\[\033[1;33m\]"
  local BLUE="\[\033[0;34m\]"
  local BLUEBOLD="\[\033[1;34m\]"
  local PURPLE="\[\033[0;35m\]"
  local PURPLEBOLD="\[\033[1;35m\]"
  local CYAN="\[\033[0;36m\]"
  local CYANBOLD="\[\033[1;36m\]"
  local WHITE="\[\033[0;37m\]"
  local WHITEBOLD="\[\033[1;37m\]"
export PS1="$GREENBOLD\u@$YELLOWBOLD\h: $CYANBOLD\w$WHITEBOLD \\$ "
}
prompt

