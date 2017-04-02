#/bin/sh
#
# create a profile on msazure for speaker verification 
# returns a profile id to be used for enrollment and authentication
#
curl -v -X POST "https://westus.api.cognitive.microsoft.com/spid/v1.0/verificationProfiles" -H "Content-Type: application/json" -H "Ocp-Apim-Subscription-Key: " --data-ascii "{
  \"locale\":\"en-us\"}"