#!/bin/bash

## SETTINGS ##
BASEPATH="$1"
PROJECTID="$2"
APIKEY="$3"
SRCZIP="$4"
CLIDIR="$5"

echo "Got Code Dx base path: $BASEPATH"
echo "Got project ID: $PROJECTID"
echo "Got API key: $APIKEY"
echo "Got Source Zip File: $SRCZIP"
echo "Got cli: $CLIDIR"

# Run some analysis tools

echo "Done running tools, zipping source files for analysis"

# Zip and include source code in analysis
#zip -r "$WORKSPACE/source.zip" "$WORKSPACE/path-to-source-files"

chmod +x $CLIDIR/codedx-client

# Start the analysis and check for errors
echo "Starting analysis..."
ANALYSIS_INFO=$(
    "$CLIDIR/codedx-client" \
        "$BASEPATH" \
        --api-key "$APIKEY" \
        analyze "$PROJECTID" \
        "$SRCZIP"
)

echo "$ANALYSIS_INFO"

# Check that the analysis at least submitted successfully
#
# (Might fail if there was an undetected file input, connection error, or some
# other issue preventing analysis startup)
#
# Note that this doesn't indicate whether the analysis actually ended
# successfully - an extra check is done afterwards for that
if [ "$?" -ne "0" ]
then
    echo "Analysis submission ended with errors"
    exit 1
fi

# Check job status
JOB_ID=$(echo "$ANALYSIS_INFO" | grep -Po "\\w+-\\w+-\\w+-\\w+-\\w+")
JOB_STATUS_JSON=$(
    curl -k -s -S \
        -H "API-Key: $APIKEY" \
        "$BASEPATH/api/jobs/$JOB_ID"
)

JOB_STATUS=$(echo "$JOB_STATUS_JSON" | grep -Po '"status":"(\w+)"')

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
        -d '{"filter":{"~status":[7, 5, 9, 4, 3], "severity":["Critical"]}}' \
        "$BASEPATH/x/projects/$PROJECTID/findings/count"
)

echo "Findings query returned JSON: $FINDINGSJSON"

NUMFINDINGS=$(echo "$FINDINGSJSON" | grep -Po "\\d+")

# Fail the pipeline if there were any findings
echo "Analysis ended with $NUMFINDINGS findings"
if [ "$NUMFINDINGS" -gt "0" ]
then
    exit 1
fi
