#!/usr/bin/env bash
#
# This script gathers some information about EC2 instances.
#
# AWS account keys are loaded from a file called AWS_CREDS within the current
# directory which has the following format:
# AWS_ACCESS_KEY="<your access key id>"
# AWS_SECRET_KEY="<your secret access key>"
#

. ./AWS_CREDS

if [[ $# -gt 0 ]]; then
  REGION_LIST="$1"
else
  REGION_LIST=$(ec2-describe-regions -O "$AWS_ACCESS_KEY" -W "$AWS_SECRET_KEY" 2>&1 | awk '{print $2}' | xargs)
fi

for REGION in $REGION_LIST; do
  echo -e "=== REGION: \033[38;33m$REGION\033[0m"
  OUTPUT=$(ec2-describe-instances -O "$AWS_ACCESS_KEY" -W "$AWS_SECRET_KEY" --region "$REGION" --hide-tags | \
    awk '{
          if ($0 ~ /^INSTANCE/) {
            if ($0 ~ /[[:space:]]running[[:space:]]/) {
              print $1" "$2" "$3" "$4" \033[38;32m"$6"\033[0m"
            } else {
              print $1" "$2" "$3 " \033[38;31m"$4"\033[0m"
            }
          } else {
            print $1" "$2
          }
        }'
  )
  if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT" | while read OUT_LINE; do
      OS_DESCR=""
      if [[ "$OUT_LINE" =~ ^INSTANCE ]]; then
        AMI=$(echo "$OUT_LINE" | awk '{print $3}')
        OS_DESCR=$(ec2-describe-images -O "$AWS_ACCESS_KEY" -W "$AWS_SECRET_KEY" "$AMI" --region "$REGION" --hide-tags | grep ^IMAGE | awk '{print $3}' | sed 's/.*\///g')
      fi
      echo -e "$OUT_LINE $OS_DESCR"
    done
  fi
done
