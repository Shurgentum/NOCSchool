#!/bin/bash
VERSION="1.0.0"
AUTHOR="Shurgentum"

# Note: Despite script creates destination folders, you should check it for existence manually
DESTINATION_PATH="$HOME/.user_backups/"
#
LOG_PATH="$HOME/.log"
LOGFILE="homebackup.log"
# Available date formats available in $(man date)
DATE_FORMAT="%d.%m.%Y-%T"

HELP_MESSAGE="This script is designed to create and save compressed backups of folders on remote using the SSH protocol. \n
\n
Usage: \n
\t $(basename $0) [--option(-o) <argument>] <directory> \n
\n
Examples: \n
\t $(basename $0) -i -a localhost <folder> \n
\t $(basename $0) -a localhost -u root <folder> \n
\n
Options: \n
\t [-i | --init ] - Exchange keys, create folders, etc... Required with first use. \n
\t [-h | --help ] - Show this screen. \n
\t [-v | --version] - Show version. \n
\t [-u | --user] - User [default: $USER]. \n
\t [-a | --address] - Destination [default: $BACKUP_ADDRESS]. \n
\n
Environment: \n
\t BACKUP_ADDRESS - destination address (exports after each use, if were provided as argument)
"

function parse() {
  # Parse CLI arguments
  # This function utilizes both UNIX and GNU style CLI arguments

  while [[ $# -gt 0 ]]; do
    key="$1"
    # Check if argument starts with "-" and save source folder if so
    if [[ $key == "-"* ]]; then
      echo "" >>/dev/null
    else
      SOURCE="$1"
      break
    fi
    # Check if $1 in list of handled arguments, execute instructions,
    # then shift arguments for 2 positions
    case $key in
    -h | --help)
      echo -e $HELP_MESSAGE
      exit 0
      ;;
    -v | --version)
      echo "$VERSION by $AUTHOR"
      exit 0
      ;;
    -i | --init)
      INIT=true
      # Shift 1 because no argument to be entered
      shift 1
      ;;
    -u | --user)
      USER="$2"
      shift 2
      ;;
    -a | --address)
      # Expoort address for easier future use
      export BACKUP_ADDRESS="$2"
      shift 2
      ;;
    *)
      echo -e "Unknown argument: $1 \n\n"
      echo -e $HELP_MESSAGE
      exit 0
      ;;
    esac
  done
}

function init() {
  mkdir -p $LOG_PATH
  touch $LOG_PATH/$LOGFILE
  ssh-copy-id $USER@$BACKUP_ADDRESS
  ssh -oBatchMode=yes $USER@$BACKUP_ADDRESS "mkdir -p $DESTINATION_PATH"
}

function checkspace() {
  SOURCE_SIZE=$(du -sb ./test/ | cut -f1)
  SOURCE_SPACE=$(df . | tail -1 | awk '{print $4}')
  DESTINATION_SPACE=$(ssh -oBatchMode=yes $USER@$BACKUP_ADDRESS "df . | tail -1 | awk '{print \$4}'")
  echo "Backup size: $SOURCE_SIZE bytes"
  echo "Source space remaining: $SOURCE_SPACE bytes"
  echo "Destination space available: $DESTINATION_SPACE bytes"
  if (($SOURCE_SIZE > $SOURCE_SPACE || $SOURCE_SIZE > $DESTINATION_SPACE)); then
    echo "No space available, exiting..."
    exit 1
  fi
}

function copy() {
  ARCHIEVE=./$(basename $1)_$(date +"$DATE_FORMAT").tar.gz
  tar -czf $ARCHIEVE $1
  # TODO: BACKUP_ADDRESS null check
  scp $ARCHIEVE $USER@$BACKUP_ADDRESS:$DESTINATION_PATH
  rm $ARCHIEVE
}

function checkdone() {
  echo -e "\n File on remote: \n"
  ssh -oBatchMode=yes $USER@$BACKUP_ADDRESS "ls -la $DESTINATION_PATH | grep '$(basename $ARCHIEVE)'"
}

function logresult() {
  if [[ $1 == 0 ]]; then
    echo "[ $(date +"$DATE_FORMAT") ] -->> Successful backup of $ARCHIEVE to $USER@$BACKUP_ADDRESS:$DESTINATION_PATH" >>$LOG_PATH/$LOGFILE
  else
    echo "[ $(date +"$DATE_FORMAT") ] -->> Backup failed! " >>$LOG_PATH/$LOGFILE
    exit $1
  fi
}

parse $@
if [[ $INIT ]]; then
  init
  if [[ $? ]]; then
    echo -e "Init successful. Now you can execute command without -i argument \n"
  fi
fi

checkspace $SOURCE
copy $SOURCE
checkdone $ARCHIEVE
logresult $?
