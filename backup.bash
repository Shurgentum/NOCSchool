#!/bin/bash
VERSION="1.0.0"
AUTHOR="Shurgentum"

# Note: Despite script creates destination folders, you should check it for existence manually
DESTINATION_PATH="/.user_backups/"
#
LOG_PATH="~/log/"
# Available date formats available in $(man date)
DATE_FORMAT="%d.%m.%Y-%T"

HELP_MESSAGE="This script is designed to create and save compressed backups of folders on remote using the SSH protocol. \n
\n
Usage: \n
\t $(basename $0) [--option(-o) <argument>] <directory> \n
\n
Examples: \n
\t $(basename $0) -i \n
\t $(basename $0) -a localhost <folder> -u root\n
\n
Options: \n
\t [-i | --init ] - Init. \n
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
      return
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
  ssh-copy-id $USER@$BACKUP_ADDRESS
  ssh -oBatchMode=yes $USER@localhost "mkdir -p ~/$DESTINATION_PATH"
}

function logresult() {
  if [[ $1 == 0 ]]; then
    echo "[ $(date +"$DATE_FORMAT") ] -->> Successful backup of $ARCHIEVE to $USER@$BACKUP_ADDRESS:~/$DESTINATION_PATH" >>$LOG_PATH/homebackup.log
  else
    echo "[ $(date +"$DATE_FORMAT") ] -->> Backup failed with code $1 (scp) " >>$LOG_PATH/homebackup.log
  fi
}

function copy() {
  ARCHIEVE=./$(basename $1)_$(date +"$DATE_FORMAT").tar.gz
  tar -czf $ARCHIEVE $1
  # TODO: BACKUP_ADDRESS null check
  scp $ARCHIEVE $USER@$BACKUP_ADDRESS:~/$DESTINATION_PATH

}

function checkspace() {
  
}

parse $@
if [[ $INIT ]]; then
  init
  return
fi
checkspace $SOURCE
copy $SOURCE
logresult $?
