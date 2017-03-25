import hashlib
import urllib
import json
import requests


class VoiceIt:
    # TODO: insert developer ID and password 
    developerId = ""
    password = ""
    
    urlUsers = 'https://siv.voiceprintportal.com/sivservice/api/users'
    urlEnrollments = 'https://siv.voiceprintportal.com/sivservice/api/enrollments'
    urlAuthentication = 'https://siv.voiceprintportal.com/sivservice/api/authentications'


    def getSHA256(self, strData):
        if strData == "":
            return self.password
        else:
            return hashlib.sha256(strData).hexdigest()

            
    def __init__(self, devId=""):
        self.developerId = devId


    def createUser(self, mail, passwd, firstName, lastName, phone1="", phone2="", phone3=""):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'application/json', "VsitEmail": email, "VsitPassword": password, "VsitDeveloperId": self.developerId,
                   "VsitFirstName": firstName, "VsitLastName": lastName, "VsitPhone1": phone1, "VsitPhone2": phone2, "VsitPhone3": phone3}
        response = ""
        try:
            response = requests.post(self.urlUsers, headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def deleteUser(self, mail, passwd):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'application/json', "VsitEmail": email,
                   "VsitPassword": password, "VsitDeveloperId": self.developerId}
        response = ""
        try:
            response = requests.delete(self.urlUsers, headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def getUser(self, mail, passwd):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'application/json', "VsitEmail": email,
                   "VsitPassword": password, "VsitDeveloperId": self.developerId}
        response = ""
        try:
            response = requests.get(self.urlUsers, headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def setUser(self, mail, passwd, firstName, lastName, phone1="", phone2="", phone3=""):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'application/json', "VsitEmail": email, "VsitPassword": password, "VsitDeveloperId": self.developerId,
                   "VsitFirstName": firstName, "VsitLastName": lastName, "VsitPhone1": phone1, "VsitPhone2": phone2, "VsitPhone3": phone3}
        response = ""
        try:
            response = requests.put(self.urlUsers, headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def createEnrollment(self, mail, passwd, pathToEnrollmentWav, contentLanguage=""):
        email = mail
        password = self.getSHA256(passwd)
        wavData = open(pathToEnrollmentWav, 'rb').read()
        headers = {'PlatformID': '2', 'Content-Type': 'audio/wav', "VsitEmail": email,
                   "VsitPassword": password, "VsitDeveloperId": self.developerId, "ContentLanguage":contentLanguage}
        response = ""
        try:
            response = requests.post(
                self.urlEnrollments, headers=headers, data=wavData)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def createEnrollmentByWavURL(self, mail, passwd, urlToEnrollmentWav, contentLanguage=""):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'audio/wav', "VsitEmail": email, "VsitPassword": password,
                   "VsitDeveloperId": self.developerId, "VsitwavURL": urlToEnrollmentWav, "ContentLanguage":contentLanguage}
        response = ""
        try:
            response = requests.post(
                self.urlEnrollments + "/bywavurl", headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def getEnrollments(self, mail, passwd):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'application/json', "VsitEmail": email,
                   "VsitPassword": password, "VsitDeveloperId": self.developerId}
        response = ""
        try:
            response = requests.get(self.urlEnrollments, headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def deleteEnrollment(self, mail, passwd, enrollmentId):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'application/json', "VsitEmail": email,
                   "VsitPassword": password, "VsitDeveloperId": self.developerId}
        response = ""
        try:
            response = requests.delete(
                self.urlEnrollments + "/" + enrollmentId, headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def authentication(self, mail, passwd, pathToAuthenticationWav, confidence="85", contentLanguage=""):
        email = mail
        password = self.getSHA256(passwd)
        wavData = open(pathToAuthenticationWav, 'rb').read()
        headers = {'PlatformID': '2', 'Content-Type': 'audio/wav', "VsitEmail": email, "VsitPassword": password, "VsitDeveloperId": self.developerId, "VsitConfidence": confidence, "ContentLanguage":contentLanguage}
        response = ""
        try:
            response = requests.post(
                self.urlAuthentication, headers=headers, data=wavData)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()


    def authenticationByWavURL(self, mail, passwd, urlToAuthenticationWav, confidence="85", contentLanguage=""):
        email = mail
        password = self.getSHA256(passwd)
        headers = {'PlatformID': '2', 'Content-Type': 'audio/wav', "VsitEmail": email, "VsitPassword": password, "VsitDeveloperId": self.developerId, "VsitwavURL": urlToAuthenticationWav, "VsitConfidence": confidence, "ContentLanguage":contentLanguage}
        response = ""
        try:
            response = requests.post(
                self.urlAuthentication + "/bywavurl", headers=headers)
            return response.text
        except requests.exceptions.HTTPError as e:
            return e.read()