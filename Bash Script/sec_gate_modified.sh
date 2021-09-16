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
SASTFINDINGSJSON=$(
    curl -k -s -S \
        -X POST \
        -H "API-Key: $APIKEY" \
        -H "Content-Type: application/json" \
        -d '{"filter":{"~status":[7, 5, 9, 4, 3], "severity":["Critical", "High"],"detectionMethod":[1]}}' \
        "$BASEPATH/x/projects/$PROJECTID/findings/count"
)

echo "SAST Findings query returned JSON: $SASTFINDINGSJSON"

SASTNUMFINDINGS=$(echo "$SASTFINDINGSJSON" | grep -Po "\d+")

# Check whether there are any active findings after that analysis finished
# (The "filter" piece is to ignore gone/resolved/etc. findings, so we only get the currently open findings)
SCAFINDINGSJSON=$(
    curl -k -s -S \
        -X POST \
        -H "API-Key: $APIKEY" \
        -H "Content-Type: application/json" \
        -d '{"filter":{"~status":[7, 5, 9, 4, 3], "severity":["Critical", "High"],"detectionMethod":[4]}}' \
        "$BASEPATH/x/projects/$PROJECTID/findings/count"
)

echo "SCA Findings query returned JSON: $SCAFINDINGSJSON"

SCANUMFINDINGS=$(echo "$SCAFINDINGSJSON" | grep -Po "\d+")

FAILBUILD=0

# Fail the pipeline if there were any findings
echo "SAST Analysis ended with $SASTNUMFINDINGS Crit/High findings"
echo "SCA Analysis ended with $SCANUMFINDINGS Crit/High findings"

if [ "$SASTNUMFINDINGS" -gt "0" ]
then
	echo "SAST findings > 0, SAST policy violated"
	FAILBUILD=1
fi

if [ "$SCANUMFINDINGS" -gt "15" ]
then
	echo "SCA findings > 15, SCA policy violated"
	FAILBUILD=1
fi

if [ "$FAILBUILD" -gt "0" ]
then
	echo "Failing Build due to policy violation."
	exit 1
fi
