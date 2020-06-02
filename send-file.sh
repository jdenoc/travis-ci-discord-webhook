#!/bin/bash

function usage () {
  echo "usage: `basename $0` [--help|--retry=<count>|--delay=<seconds>] file_path webhook_url"
  echo ""
  echo "  --help                             display this help/usage dialog"
  echo "  --retry=<count>                    amount of times you wish to attempt to retry uploading"
  echo "  --delay=<seconds>                  set the delay between retries in second(s) default: 2.5 seconds"
  echo "  --ext=<acceptable file extension>  file extension of files that are permitted for transmission"
  echo "  <file_path>                        directory where fiels you wish to upload to discord are located"
  echo "  <webhook_url>                      discord webhook URL"
}

# CHECK: file_path provided
if [[ -z $1 ]]; then
  echo -e "WARNING!!\nYou need to pass a file path to the directory where files you intend to upload to discord are located, as the first argument to this script."
  exit 1
fi

# check options
RETRY_COUNT=0
RETRY_DELAY=2.5
VALID_EXT=()
for i in "$@"; do
case $i in
    --help)  # provide HELP dialog
      usage
      exit 1
    ;;
    --delay=*)  # how many seconds of a delay between retries
      RETRY_DELAY="${i#*=}"
      shift # past argument=value
    ;;
    --retry=*)  # how many times the script should retry uploading files to discord
      RETRY_COUNT="${i#*=}"
      shift # past argument=value
    ;;
    --ext=*)
      VALID_EXT+=("${i#*=}")
      shift # past argument=value
	;;
    *)
      # unknown option
    ;;
esac
done

# CHECK: file_path is a directory
if [[ ! -d $1 ]]; then
  if [[ ! -L $1 ]]; then
    echo -e "WARNING!!\nFile path provided does not exist"
    exit 1
  fi
fi

# CHECK: provided directory ends in a "/"
if [[ ${1: -1} != "/" ]]; then
  FILE_PATH="$1/"
else 
  FILE_PATH=$1
fi

# CHECK: webhook_url provided
if [[ -z $2 ]]; then
  echo -e "WARNING!!\nYou need to pass the a discord webhook URL as the second argument to this script."
  exit 1
fi
WEBHOOK_URL=$2

function send_file_to_discord () {
  FILENAME="$1"
  WEBHOOK_URL="$2"
  BASE_FILENAME=$(basename "$filename")

  WEBHOOK_DATA='{
    "embeds":[{
         "description": "'$BASE_FILENAME'"
	  }]
  }'
  
  echo -e "\\n[Webhook]: Sending file via webhook..."
  (
    curl \
	  --fail \
	  --progress-bar \
	  -A "TravisCI-Webhook" \
	  -H "Content-Type: multipart/form-data" \
	  -F "payload_json=$WEBHOOK_DATA" \
	  -F "file=@$FILENAME" \
	  $WEBHOOK_URL \
    && echo -e "\\n[Webhook]: Successfully sent file via webhook."
  ) || echo -e "\\n[Webhook]: Unable to send file via webhook."
}

function find_files_to_send () {
  FILE_PATH="$1"
  WEBHOOK_URL="$2"

  # cycle through all the files in the given directory and send to discord via webhook_url
  FILE_AVAILABLE=false
  for file_ext in ${VALID_EXT[*]}; do
    for filename in $FILE_PATH*.$file_ext; do
      if [[ ! -e $filename ]]; then
        continue;
      fi;
      FILE_AVAILABLE=true
      echo -e "\\n[Webhook]: Preparing to send '$filename'"
      send_file_to_discord "$filename" "$WEBHOOK_URL"
    done
  done

  if ! $FILE_AVAILABLE ; then
    echo -e "\\n[Webhook]: No files available to send to discord";
  fi;
}

COUNTER=0
while [ $COUNTER -le $RETRY_COUNT ]
do
  find_files_to_send "$FILE_PATH" "$WEBHOOK_URL"

  if $FILE_AVAILABLE; then # FILE_AVAILABLE value comes from find_files_to_send()
    COUNTER=$RETRY_COUNT
  fi
  ((COUNTER++))
  if [[ $COUNTER -le $RETRY_COUNT ]]; then
    echo -e "\\n[Webhook]: re-checking for files $(( $RETRY_COUNT - $COUNTER + 1 )) more time(s)"
    sleep $RETRY_DELAY  # wait for $RETRY_DELAY seconds
  fi;
done
