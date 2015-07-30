[ -f /etc/bashrc ] && . /etc/bashrc
[ -n "$PS1" ] && [ -f /etc/bash_completion ] && . /etc/bash_completion

shopt -s histappend
HISTCONTROL=ignoredups:ignorespace:ignoreboth
HISTSIZE=1000000
HISTTIMEFORMAT="%F %T "

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

function setps1 {
  if [ `whoami`   != "zuserm"       ]; then local u="\u"  ; fi
  if [ `hostname` != "zuserm-hp15t" ]; then local h="@\h" ; fi
  PS1="\[\033[G\]\t|$u$h:\w"'$(__git_ps1 "|%.2s")'"$ "
}
if [ -n "PS1" ]; then setps1 ; fi


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

export GHC_HP_VERSION="7.6.3"
pathPrepend  \
  $HOME/.cabal-$GHC_HP_VERSION/bin  \
  $HOME/.ghc-$GHC_HP_VERSION/bin    \
  $HOME/bin                         \
  $HOME/Ork/bin                     \
;

export HD='/media/Charybdis/zuserm'
alias  HD="cd $HD"
export TEXINPUTS=".:"

#make a wild guess at the DISPLAY you might want
if [[ -z "$DISPLAY" ]]; then
  export DISPLAY=`ps -ef | grep /usr/bin/X | grep ' :[0-9] ' -o | grep :[0-9] -o`
fi

for cmd in wconnect wauto tether resolv \
           mnt optimus xorg-conf bluetooth fan intel-pstate flasher
do alias $cmd="sudo $cmd"; done

alias time="command time"
alias mkdir="mkdir -p"
alias :l='ghci'
alias :h='man'
alias :q='exit'
alias :r='. /etc/profile; . ~/.bashrc;'

function e            { email.pl --print "$@"; }
function vol          { pulse-vol "$@"; }
function ls           { command ls --color=auto "$@"; }
function l            { ls -alh "$@"; }
function ll           { l "$@"; }
function ld           { l -d "$@"; }
function i            { feh -FZ "$@" ; }
function xmb          { xmonad-bindings "$@"; }
function g            { git "$@"; }
function gs           { g s "$@"; }
function grep         { command grep --color=auto "$@"; }
function hat          { highlight --out-format=ansi --force "$@"; }
function codegrep     { grep -RIhA "$@"; }
function tags         { tags id3v2 -l "$@"; }
function enc          { gpg -r "$USER" -o "$@.gpg" -e "$@"; rm "$@"; }
function dec          { gpg -o `basename "$@" .gpg` -d "$@"; }
function printers     { sudo system-config-printer "$@"; }
function evi          { spawn evince "$@"; }
function snapshot     { backup --snapshot "$@"; }
function qgroups-info { backup --info --quick --sort-by=size "$@"; }
function escape-pod   { ~/.src-cache/escapepod/escape-pod-tool --escapepod "$@"; }
function podcastle    { ~/.src-cache/escapepod/escape-pod-tool --podcastle "$@"; }
function pseudopod    { ~/.src-cache/escapepod/escape-pod-tool --pseudopod "$@"; }
function j            { fcron-job-toggle "$@"; }
function mp           { mpv "$@"; }
function mpu          {
  if [ -z $2 ] ; then local default_quality='best' ; fi
  livestreamer "$@" $default_quality
}

function spawn        { "$@" & disown; }
function spawnex      { "$@" & disown && exit 0; }
function s            { "$@" & disown; }
function sx           { "$@" & disown && exit 0; }
function vims         { vim `which $1`; }

function cbi          { spawn chromium-browser --incognito "$@"; }
function tex2pdf      { pdflatex -halt-on-error "$1".tex && evince "$1".pdf; }

function first        { ls "$@" | head -1; }
function last         { ls "$@" | tail -1; }
function apN          { let n=${#@}; "$2" "${@:3:$1-1}" "${!n}" "${@:$1+2:$n-$1-2}"; }

# common typos
function mkdit        { mkdir "$@"; }
function cim          { vim "$@"; }
function bim          { vim "$@"; }

# games
function mkSteamFuncs {
  function mkSteamFuncs_getAppManifestValue {
    local app_path key
    read  app_path key <<< "$@"
    cat $app_path | egrep "^[[:space:]]*\"$key\"" \
                  | sed "s/^[[:space:]]*\"$key\"[[:space:]]*\"//" \
                  | sed "s/\"[[:space:]]*\$//"
  }

  for app_path in $(ls  ~/.steam/steamapps/*.acf); do
    local app_id=`mkSteamFuncs_getAppManifestValue "$app_path" "appid"`
    local app_name=`mkSteamFuncs_getAppManifestValue "$app_path" "name"`
    local app_name_clean=`echo -n $app_name | tr -c [[:alnum:]] _`
    eval "function steam_$app_name_clean { steam steam://rungameid/$app_id ; }"
  done
}
mkSteamFuncs

function execAlarm() {
  $@
  exitCode="$?"
  if [ $exitCode == 0 ]; then
    alarm -s success
  else
    alarm -s failure
  fi
  bash -c "exit $exitCode"
}

function update-repo {
  repo="$1"
  shift
  sudo apt-get update \
    -o Dir::Etc::sourcelist="sources.list.d/$repo" \
    -o Dir::Etc::sourceparts="-" \
    -o APT::Get::List-Cleanup="0" \
    "$@"
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

# allow <C-S> in vim
stty stop undef

function clean-home {
  rm -f .viminf*.tmp .recently-used
} ; clean-home
