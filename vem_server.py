#
# Vox Ex Machina OSC UDP Server / Client
# 
# graeme@lolux.net July 2016
#  
# Receives filenames of audio files from MAX/MSP 
#
# Audio files are machine generated samples for
# speaker recognition / voice verification systems
#
# The server will then attempt a brute force attack 
# various APIs using the samples
#

import argparse
import math
import sys
import time
import json
import subprocess

# osc
from pythonosc import dispatcher
from pythonosc import osc_server
from pythonosc import osc_message_builder
from pythonosc import udp_client

# internal api
import dynamic
import analysis_2
import os
import tempfile

# voiceit
from voiceit import *
# msazure
from msazure import *

# server and client
global vox_server
global vox_udp
global count
global userid 
global password
global voice
global azure


# utility messages ############################################################

# stop server
def exit_handler(unused_addr, args, localmsg):
    msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
    msg.add_arg("vox> server...exit")
    msg = msg.build()
    vox_udp.send(msg)
    vox_server.shutdown()


# helo return version 
def helo_handler(unused_addr, args, localmsg):
    msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
    msg.add_arg("vox> server...ok")
    msg = msg.build()
    vox_udp.send(msg)

# test osc comms is working 
def test_handler(unused_addr, args, filename):
    msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
    msg.add_arg("vox> server...ack")
    msg = msg.build()
    vox_udp.send(msg)


# select userid for any API
def user_handler(unused_addr, args, user):
	# set username
	global userid
	userid = user
	print(userid)


# voice it api ###################################################################
def voiceit_auth_handler(unused_addr, args, filename):
	print("authenticating " + userid)
	vox_result = json.loads(voice.authentication(userid, password, filename))
	vox_code = vox_result['ResponseCode']
	fileinfo = os.path.split(filename)
	vox_msg = "".join(["vit> ", fileinfo[1], " ", vox_result['Result']])
	
	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)

	
def voiceit_enrol_handler(unused_addr, args, filename):
	print("enrolling " + userid)	
	vox_result = json.loads(voice.createEnrollment(userid, password, filename))
	vox_code = vox_result['ResponseCode']
	fileinfo = os.path.split(filename)
	vox_msg = "".join(["vit> ", fileinfo[1], " ", vox_result['Result']])
	
	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)


# ms azure api ######################################################################
def msazure_auth_handler(unused_addr, args, filename): 
	print("authenticating " + userid)
	vox_result = json.loads(azure.authentication(userid, password, filename))
	fileinfo = os.path.split(filename)
	try:
		vox_msg = "".join(["msa> ", fileinfo[1], " ", vox_result['result'], " ", vox_result['confidence']])
	except Exception as e:
		vox_msg = "".join(["msa> ", fileinfo[1], " ", vox_result['message']])
	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)

	
def msazure_enrol_handler(unused_addr, args, filename):
	print("enrolling " + userid)
	vox_result = json.loads(azure.createEnrollment(userid, password, filename))
	fileinfo = os.path.split(filename)
	try:
		vox_msg = "".join(["msa> ", fileinfo[1], " ", vox_result['enrollmentStatus']])
	except Exception as e:
		vox_msg = "".join(["msa> ", fileinfo[1], " Error ", vox_result['error']['message']])
	
	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)

# internal api #######################################################################
def internal_auth_handler(unused_addr, args, filename):
	# pyvox internal API comparison
	template = "/home/graeme/Research/voxexmachina/sc/never.wav"
	seqx = analysis_2.master(template)
	seqy = analysis_2.master(filename)
	cost = dynamic.dynamicTimeWarp(seqx, seqy)
	match = dynamic.match_test(cost)
	fileinfo = os.path.split(filename)
	if match:
		vox_msg = "".join(["int> SUC ", fileinfo[1], " ", str(cost)])
	else:
		vox_msg = "".join(["int> ", fileinfo[1], " Failed ", str(cost)])

	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)


def internal_enrol_handler(unused_addr, args, filename):
	#enrol internal api
	print("enrolling " + userid)
	# TODO select file and overwrite user template file for comparison
	

# main loop #############################################################################
if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("--ip", default="127.0.0.1", help="The IP to listen on")
	parser.add_argument("--port", type=int, default=7678, help="The port to listen on")
	args = parser.parse_args()

	# initialise VoiceIt API 
	voice = VoiceIt()
	#initialise the MSAzure API 
	azure = MSAzure()

	# user
	userid = "*"
	# TODO: hardcoded in voiceit / msazure doesn't need it...?
	password=""

	# client listening on local ip only
	vox_udp = udp_client.SimpleUDPClient('127.0.0.1', 57120)
	# client listening on network ip
	#vox_udp = udp_client.SimpleUDPClient('10.20.15.117', 57120)
	
	dispatcher = dispatcher.Dispatcher()
	dispatcher.map("/vox/helo", helo_handler, "helo")
	dispatcher.map("/vox/exit", exit_handler, "exit")
	dispatcher.map("/vox/test", test_handler, "test")

	# user_id selected for api
	dispatcher.map("/vox/api/user", user_handler, "api_user")
	# internal API
	dispatcher.map("/vox/api/auth/internal", internal_auth_handler, "internal_auth")
	dispatcher.map("/vox/api/enrol/internal", internal_enrol_handler, "internal_enrol")
	# voiceit API
	dispatcher.map("/vox/api/auth/voiceit", voiceit_auth_handler, "voiceit_auth")
	dispatcher.map("/vox/api/enrol/voiceit", voiceit_enrol_handler, "voiceit_enrol")
	# ms azure API
	dispatcher.map("/vox/api/auth/msazure", msazure_auth_handler, "msazure_auth")
	dispatcher.map("/vox/api/enrol/msazure", msazure_enrol_handler, "msazure_enrol")

	# make the server
	vox_server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)
	vox_server.serve_forever()
	
