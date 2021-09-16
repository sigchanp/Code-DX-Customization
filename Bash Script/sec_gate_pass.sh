#!/bin/bash

export LC_ALL=en_US.utf8

## SETTINGS ##
BASEPATH="$1"
PROJECTID="$2"
APIKEY="$3"

echo "Got Code Dx base path: $BASEPATH"
echo "Got project ID: $PROJECTID"
echo "Got API key: $APIKEY"

JOB_STATUS_JSON=$(
		curl -k -s -S \
			-H "API-Key: $APIKEY" \
			"$BASEPATH/api/projects/$PROJECTID/incomplete-work"
	)
	
JOB_ID=$(echo "$JOB_STATUS_JSON" | grep -Po '"jobId":"\K([a-zA-Z0-9\-]+)')
JOB_STATUS=$(echo "$JOB_STATUS_JSON" | grep -Po '"status":"(\w+)"')

echo "Found Job $JOB_ID: $JOB_STATUS"

while [ "$JOB_STATUS" == '"status":"running"' ]; do
	sleep 10
	# Check job status
	JOB_STATUS_JSON=$(
    curl -k -s -S \
        -H "API-Key: $APIKEY" \
        "$BASEPATH/api/jobs/$JOB_ID"
	)

	JOB_STATUS=$(echo "$JOB_STATUS_JSON" | grep -Po '"status":"(\w+)"')
	echo "Polling Job: $JOB_STATUS"
done

if [ "$JOB_STATUS" != '"status":"completed"' ]
then
    echo "Analysis failed"
    exit 1
fi

# Check whether there are any active findings after that analysis finished
# (The "filter" piece is to ignore gone/resolved/etc. findings, so we only get the currently open findings)
FINDINGSJSON=$(
    curl -k -s -S \
        -X POST \
        -H "API-Key: $APIKEY" \
        -H "Content-Type: application/json" \
        -d '{"filter":{"~status":[7, 5, 9, 4, 3],"status":["new"], "severity":["Critical", "High"]}}' \
        "$BASEPATH/x/projects/$PROJECTID/findings/count"
)

echo "Findings query returned JSON: $FINDINGSJSON"

NUMFINDINGS=$(echo "$FINDINGSJSON" | grep -Po "\d+")

# Fail the pipeline if there were any findings
echo "Analysis ended with $NUMFINDINGS findings"
if [ "$NUMFINDINGS" -gt "0" ]
then
	echo "Security Policy Violated, Failing Build"
    exit 1
fi
