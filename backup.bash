#!/bin/bash
VERSION="1.0.0"
AUTHOR="Shurgentum"

# Note: If you want to change the name of the destination folder, you should check it for existence
DESTINATION_PATH="."

HELP_MESSAGE="This script is designed to create and save compressed backups of folders on remote using the SSH protocol. \n
\n
Usage: $(basename $0) [--option(-o) <argument>] <directory> \n
\n
Options: \n
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
      echo "" >> /dev/null
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


function copy() {
  # if [[ -z "$BACKUP_ADDRESS" ]];
  # then
  #   scp -r $SOURCE $USER@$BACKUP_ADDRESS:~/$DESTINATION_PATH/$(basename $SOURCE)_$(date +"%d.%m.%Y-%T")
  # else
  #   echo "Destinaton address was not specified"
  # fi

  ARCHIEVE=./$(basename $1)_$(date +"%d.%m.%Y-%T").tar.gz
  tar -czf $ARCHIEVE $1
  scp $ARCHIEVE $USER@$BACKUP_ADDRESS:~/$DESTINATION_PATH
  rm $ARCHIEVE
  echo "$ARCHIEVE"
}

function log(){
  mkdir ~/log
  echo "Successfully "
}

parse $@
copy $SOURCE
