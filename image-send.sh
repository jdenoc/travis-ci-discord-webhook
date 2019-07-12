#!/bin/bash

function usage () {
  echo "usage: `basename $0` [--help] file_path webhook_url"
  echo ""
  echo "  --help         display this help/usage dialog"
  echo "  file_path      directory where images you wish to upload to discord are located"
  echo "  webhook_url    discord webhook URL"
}

# CHECK: file_path provided
if [[ -z $1 ]]; then
  echo -e "WARNING!!\nYou need to pass a file path to the directory where images you intend to upload to discord are located, as the first argument to this script."
  exit 1
fi

# provide HELP dialog
if [[ $1 == "--help" ]]; then
  usage
  exit
fi

# CHECK: webhook_url provided
if [[ -z $2 ]]; then
  echo -e "WARNING!!\nYou need to pass the a discord webhook URL as the second argument to this script."
  exit 1
fi
WEBHOOK_URL=$2

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

function send_image_to_discord () {
  FILENAME="$1"
  WEBHOOK_URL="$2"
  BASE_FILENAME=$(basename "$filename")


  WEBHOOK_DATA='{
    "embeds":[{
         "description": "'$BASE_FILENAME'"
	}]
  }'
  
  echo -e "\\n[Webhook]: Sending image via webhook..."
  (
    curl \
	  --fail \
	  --progress-bar \
	  -A "TravisCI-Webhook" \
	  -H "Content-Type: multipart/form-data" \
	  -F "payload_json=$WEBHOOK_DATA" \
	  -F "file=@$FILENAME" \
	  $WEBHOOK_URL \
    && echo -e "\\n[Webhook]: Successfully sent image via webhook."
  ) || echo -e "\\n[Webhook]: Unable to send image via webhook."
}

# cycle through all the image files in the given directory and send to discord via webhook_url
IMAGE_AVAILABLE=false
for filename in $FILE_PATH*.{jpg,JPG,png,PNG,JPEG,jpeg,gif,GIF}; do
  if [[ ! -e $filename ]];
    then continue;
  fi;
  IMAGE_AVAILABLE=true
  echo -e "\\n[Webhook]: Preparing to send '$filename'"
  send_image_to_discord "$filename" "$WEBHOOK_URL"
done

if ! $IMAGE_AVAILABLE ;
  then echo -e "\\n[Webhook]: No images available to send to discord";
fi;
