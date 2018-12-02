#!/bin/bash

#Menu driven command line server configurator for Squad
#squad should be setup under a user named squad
#this script expects the use of TMUX to run the server

#These should be the location of various squad folders
cfgdir="/home/squadserver/serverfiles/Squad/ServerConfig"
homedir="/home/squadserver/"
svrroot="/home/squad/squadserver/server1/"

#Squad-Servers.com URL
sqdsrvsurl="https://squad-servers.com/server/1111/"

#printf colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

usage() {
  cat << EOF
    Squad configurator v2
    Usage: ./squadconfig.sh (options)
      -h, --help            display this help and exit
      -r, --reload          update and restart the server
      -s, --stop            shutdown the squad server

Examples:
  ./squadconfig.sh          Start configurator in interactive mode
  ./squadcondig.sh -r       Update the server, reboot, and exit the script
EOF
    #' Fix syntax highlight on sublime
    exit $1
}

spinner (){
    local pid=$!
    local delay=1.00
    local spinstr='...'
    echo "Loading "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "%s  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "    \b\b\b\b"
}

admins (){
  nano $cfgdir/Admins.cfg
}

bans (){
  #nano $cfgdir/Bans.cfg
  cat $cfgdir/Bans.cfg
  printf '\nPlease type a string or partial match of the ban you like to remove
  or enter nothing to go back: '
  read banstring
  if [[ $banstring != "" ]]; then
    printf "\nBan removed marked in RED\n"
    cat $cfgdir/Bans.cfg | egrep --color -B 3 -A 3 "$banstring"
    grep -v "$banstring" $cfgdir/Bans.cfg > $cfgdir/Bans.cfg.tmp
    cp $cfgdir/Bans.cfg.tmp $cfgdir/Bans.cfg
  fi
}

maps (){
    nano $cfgdir/MapRotation.cfg
}

servercfg (){
    nano $cfgdir/Server.cfg
}

reload (){
    printf "Please Stand By..."
    $homedir/squadserver update
    $homedir/squadserver start
    read -p "Force reboot? (Y/N) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
        then
                stop
                start
        fi
}

forcereload (){
    $homedir/squadserver force-update
}

start (){
    $homedir/squadserver start
}

stop (){
    $homedir/squadserver stop
}

svrstats (){
  printf 'Please stand by, collecting stats...'
  local mapname="$(curl -s -X GET "$sqdsrvsurl" | grep -A 1 "<strong>Map</strong>" | grep -v "class" | sed -e 's/\<strong\>//g' | sed -e 's/\<td\>//g' |sed 's/[^a-z  A-Z 0-9]//g')"
  local playercount="$(curl -s -X GET "$sqdsrvsurl" | grep -A 2 "<strong>Players</strong>" | egrep -v "Players" | sed -e 's/\<strong\>//g' | sed -e 's/\<td\>//g' | sed 's/[^a-z A-Z 0-9 /]//g'| grep "/")"
  clear
  printf '\nServer stats:\n'
  printf "$(uptime)
  "
  free -mh
  if pgrep -x "SquadServer" > /dev/null
    then
      printf '\n'
      ps aux | grep TIME | grep COMMAND
      printf "$(ps aux | grep SquadServer --color | grep -v .sh | grep -v grep)
      "
      printf "
      CPU Usage: $(ps axco %cpu,command | grep SquadServer | grep -v .sh)   |   Current Map: $mapname
      "
      printf "RAM Usage: $(ps axco %mem,command | grep SquadServer | grep -v .sh)   |   Players:     $playercount
      "
      printf "
      ${grn}The server is ONLINE. ${end}
      "
    else
      printf "
      ${red}The server is OFFLINE.${end}
      "
  fi
}



if [[ $# -eq 0 ]]; then
  selection=
  until [ "$selection" = "0" ]; do
    printf '\nSquad Config Menu:
    1) Server status              5) Change MapRotation
    2) Remove Bans                6) Reboot, Update, and Start
    3) Edit Admins                7) Stop Server
    4) Server Configuration       0) Quit
'
    read selection
      case $selection in
          1 ) svrstats ;;
          2 ) bans ;;
          3 ) admins ;;
          4 ) servercfg ;;
          5 ) maps ;;
          6 ) read -p "Update and restart the server? (Y/N) " -n 1 -r
              if [[ $REPLY =~ ^[Yy]$ ]]
                then
                  reload
              fi
              ;;
          7 ) read -p "Stop the server? (Y/N) " -n 1 -r
              if [[ $REPLY =~ ^[Yy]$ ]]
                then
                  stop
              fi
              ;;
          0 ) exit ;;
          * ) printf "%s\n" "${red}--> ERROR: Invalid Option <--${end}"
      esac
  done
else
  while [ ! $# -eq 0 ]
  do
        case "$1" in
          --help | -h )   usage
                          exit
                          ;;
          --reload | -r ) forcereload
                          exit
                          ;;
          --stop | -s )   stop
                          exit
                          ;;
        esac
        shift
  done
fi
