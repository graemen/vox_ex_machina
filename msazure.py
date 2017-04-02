# MS Azure API for Speaker Verification
#
# Container WAV
# Encoding    PCM
# Rate    16K
# Sample Format   16 bit
# Channels    Mono
#
# supported phrases for text dependent verification:
#
#    "i am going to make him an offer he cannot refuse"
#    "houston we have had a problem"
#    "my voice is my passport verify me"
#    "apple juice tastes funny after toothpaste"
#    "you can get in without your password"
#    "you can activate security system now"
#    "my voice is stronger than passwords"
#    "my password is not your business" 
# ***   "my name is unknown to you"
#    "be yourself everyone else is already taken"

import http.client
import urllib.request
import urllib.parse
import urllib.error
import base64

class MSAzure:

    headers = {
        # Request headers
        'Content-Type': 'application/json',
        'Ocp-Apim-Subscription-Key': '',
    }

    params = urllib.parse.urlencode({
    })

    def createUser(self):
        # create a profile
        try:
            body = "{\"locale\":\"en-us\"}/n/n"
            conn = http.client.HTTPSConnection('westus.api.cognitive.microsoft.com')
            conn.request("POST", "/spid/v1.0/verificationProfiles", body, self.headers)
            response = conn.getresponse()
            data = response.read().decode('utf-8')
            return data
            conn.close()
        except Exception as e:
            print("[Errno {0}] {1}".format(e.errno, e.strerror))


    def createEnrollment(self, userid, passwd, pathToWav, contentLanguage="" ):
        # create an enrollment for a profile
        try:
            body = open(pathToWav, 'rb').read()
            conn = http.client.HTTPSConnection('westus.api.cognitive.microsoft.com')
            uri = "".join(["/spid/v1.0/verificationProfiles/",userid,"/enroll?"])
            conn.request("POST", uri, body, self.headers)
            response = conn.getresponse()
            data = response.read().decode('utf-8')
            return data
            conn.close()
        except Exception as e:
            print("[Errno {0}] {1}".format(e.errno, e.strerror))


    def getPhrases(self, locale, body="/n/n"):
        # get verification phrases
        try:
            conn = http.client.HTTPSConnection('westus.api.cognitive.microsoft.com')
            conn.request("GET", "/spid/v1.0/verificationPhrases?locale=en-us", body, self.headers)
            response = conn.getresponse()
            data = response.read().decode('utf-8')
            return data
            conn.close()
        except Exception as e:
            print("[Errno {0}] {1}".format(e.errno, e.strerror))


    def authentication(self, userid, password, pathToWav, confidence="85", contentLanguage=""):
        # authentication (speaker verification)
        try:
         
            body = open(pathToWav, 'rb').read()
            conn = http.client.HTTPSConnection('westus.api.cognitive.microsoft.com')
            uri = "".join(["/spid/v1.0/verify?verificationProfileId=",userid])
            print(uri)
            conn.request("POST", uri, body, self.headers)
            response = conn.getresponse()
            data = response.read().decode('utf-8')
            return data
            conn.close()
            
        except Exception as e:
            print("[Errno {0}] {1}".format(e.errno, e.strerror))
