[ -f /etc/bashrc ] && . /etc/bashrc
[ -n "$PS1" ] && [ -f /etc/bash_completion ] && . /etc/bash_completion

shopt -s dotglob
shopt -s extglob

ssh-add ~/.ssh/id_rsa 2> /dev/null
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=1000000
# ignoredups: do not add duplicate history entries
# ignoredspace: do not add history entries that start with space
export HISTCONTROL=ignoredups:ignorespace
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/

shopt -s checkwinsize # update LINES and COLUMNS based on window size
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)" #less on binary files, e.g. tars

#rxvt-unicode and rxvt-256color => rxvt {for legacy}
case "$TERM" in rxvt*) TERM=rxvt ;; esac

#use prompt_cmd to set the window title => $WINDOW_TITLE or "Terminal: pwd"
#only for rxvt* terms
if [ "$TERM" == "rxvt" ]; then
  p1='echo -ne "\033]0;$WINDOW_TITLE\007"'
  p2='echo -ne "\033]0;Terminal: ${PWD/$HOME/~}\007"'
  PROMPT_COMMAND='if [ "$WINDOW_TITLE" ]; then '$p1'; else '$p2'; fi'
fi

###horrible fucking oracle variables
if [[ -z "$ORACLE_HOME" ]] && [[ -f /etc/ld.so.conf.d/oracle.conf ]]; then
  oralibdir=`cat /etc/ld.so.conf.d/oracle.conf`
  export ORACLE_HOME=`dirname "$oralibdir"`
fi
if [[ -z "$SQLPATH" ]] && [[ -n "$ORACLE_HOME" ]]; then
  export SQLPATH=$ORACLE_HOME/lib
fi
###

pathAppend ()  { for x in $@; do pathRemove $x; export PATH="$PATH:$x"; done }
pathPrepend () { for x in $@; do pathRemove $x; export PATH="$x:$PATH"; done }
pathRemove ()  { for x in $@; do
  export PATH=`\
    echo -n $PATH \
    | awk -v RS=: -v ORS=: '$0 != "'$1'"' \
    | sed 's/:$//'`;
  done
}

pathAppend          \
  $HOME/bin         \
  $HOME/.cabal/bin  \
  /usr/local/bin    \
  /usr/bin          \
  /bin              \
  /usr/local/sbin   \
  /usr/sbin         \
  /sbin             \
  /usr/local/games  \
  /usr/games        \
;

meego_gnu=/opt/gnu-utils
if [ -d $meego_gnu ]; then
  pathPrepend              \
    /usr/libexec/git-core  \
    $meego_gnu/bin         \
    $meego_gnu/usr/bin     \
    $meego_gnu/usr/sbin    \
  ;
fi

#command prompt
tarcmd='`__sb_tarname`'

if [[ -z "$DISPLAY" ]]; then
  export DISPLAY=':2'
fi

colon=":"
c1='\[\033[01;32m\]'
c2='\[\033[01;34m\]'
cEnd='\[\033[00m\]'

if [ -n "PS1" ]; then
  PS1="${c1}sbox-${tarcmd}$cEnd$colon$c2\w$cEnd\$ "
fi

for exitTypo in exot exut
do alias $exitTypo='exit'; done

alias time="command time"
alias mkdir="mkdir -p"
alias :q='exit'
alias :r='. /etc/profile; . ~/.bashrc;'

function dus          { du -s * | sort -g "$@"; }
function killjobs     { kill -9 `jobs -p` 2>/dev/null; sleep 0.1; echo; }
function cx           { chmod +x "$@"; }
function l            { ls -Al --color=auto "$@"; }
function ll           { ls -Al --color=auto "$@"; }
function ld           { ls -dAl --color=auto "$@"; }
function perms        { stat -c %a "$@"; }
function g            { git "$@"; }
function gs           { g s "$@"; }

function s            { "$@" & disown; }
function sx           { "$@" & disown && exit 0; }
function spawn        { "$@" & disown; }
function spawnex      { "$@" & disown && exit 0; }

function first        { ls "$@" | head -1; }
function last         { ls "$@" | tail -1; }

# common typos
function mkdit        { mkdir "$@"; }
function cim          { vim "$@"; }
function bim          { vim "$@"; }

function find() {
  command find "$@"
}

function grep() {
  command grep -s "$@"
}

function git-log() {
  git logn "$@"
}
function git() {
  realgit="$(which git)"
  realcmd="$1"
  fct="git-$realcmd"
  if [ "$(type -t $fct)" = "function" ]; then
    shift
    $fct "$@"
  elif [[ "$realcmd" == *-real ]]; then
    shift
    cmd=${realcmd%-real}
    $realgit $cmd "$@"
  else
    $realgit "$@"
  fi
}
