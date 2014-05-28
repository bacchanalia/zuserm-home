[ -f /etc/bashrc ] && . /etc/bashrc
[ -n "$PS1" ] && [ -f /etc/bash_completion ] && . /etc/bash_completion

shopt -s histappend
HISTCONTROL=ignoredups:ignorespace:ignoreboth
HISTSIZE=1000000

export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/

shopt -s checkwinsize
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
ssh-add ~/.ssh/id_rsa 2> /dev/null

case "$TERM" in rxvt*) TERM=rxvt ;; esac

if [ "$TERM" == "rxvt" ]; then
  p1='echo -ne "\033]0;$WINDOW_TITLE\007"'
  p2='echo -ne "\033]0;Terminal: ${PWD/$HOME/~}\007"'
  PROMPT_COMMAND='if [ "$WINDOW_TITLE" ]; then '$p1'; else '$p2'; fi'
fi

if [ -n "PS1" ]; then
  PS1="\[\033[G\]$PS1"
fi

pathAppend ()  { for x in $@; do pathRemove $x; export PATH="$PATH:$x"; done }
pathPrepend () { for x in $@; do pathRemove $x; export PATH="$x:$PATH"; done }
pathRemove ()  { for x in $@; do
  export PATH=`\
    echo -n $PATH \
    | awk -v RS=: -v ORS=: '$0 != "'$1'"' \
    | sed 's/:$//'`;
  done
}

if [ -n "$PS1" ]; then
  pathAppend          \
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
fi

export GHC_HP_VERSION="7.6.3"
pathPrepend  \
  $HOME/.cabal-$GHC_HP_VERSION/bin  \
  $HOME/.ghc-$GHC_HP_VERSION/bin    \
  $HOME/bin                         \
;

export HD='/media/Charybdis/zuserm'
alias  HD="cd $HD"
export TEXINPUTS=".:"

#make a wild guess at the DISPLAY you might want
if [[ -z "$DISPLAY" ]]; then
  export DISPLAY=`ps -ef | grep /usr/bin/X | grep ' :[0-9] ' -o | grep :[0-9] -o`
fi

function time         { command time $@; }
function mkdir        { mkdir -p $@; }

function vol          { pulse-vol $@; }
function ls           { ls --color=auto $@; }
function l            { ls -alh $@; }
function ll           { l $@; }
function ld           { l -d $@; }
function g            { git $@; }
function grep         { grep --color=auto $@; }
function hat          { highlight --out-format=ansi --force $@; }
function codegrep     { grep -RIhA $@; }
function rmplayer     { rm $@; }
function tags         { tags id3v2 -l $@; }
function lk           { sudo chown -R root. $@; }
function ulk          { sudo chown -R zuserm. $@; }
function printers     { sudo system-config-printer $@; }
function evi          { spawn evince $@; }
function snapshot     { backup --snapshot $@; }
function groups-info  { backup --info --quick --sort-by=size $@; }

function :l           { ghci; }
function :h           { man; }
function :q           { exit; }
function :r           { . /etc/profile; . ~/.bashrc; }

function cbi          { spawn chromium-browser --incognito $@; }
function tex2pdf      { pdflatex -halt-on-error "$1".tex && evince "$1".pdf ; }

#alias o='gnome-open'

for cmd in wconnect wauto tether resolv \
           mnt optimus xorg-conf bluetooth fan intel-pstate flasher
do alias $cmd="sudo $cmd"; done

function spawn        { $@ & disown ; }
function spawnex      { $@ & disown && exit 0 ; }
function vims         { vim `which $1` ; }

function update-repo  { sudo apt-get update \
                         -o Dir::Etc::sourcelist="sources.list.d/$1" \
                         -o Dir::Etc::sourceparts="-" \
                         -o APT::Get::List-Cleanup="0"
}

function git-log()    { git ln $@; }
function git() {
  realgit="$(which git)"
  cmd="git-$1"
  if [ "$(type -t $cmd)" = "function" ]; then
    shift
    $cmd "$@"
  else
    $realgit "$@"
  fi
}

# allow <C-S> in vim
stty stop undef
