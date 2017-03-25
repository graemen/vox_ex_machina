# 	This file is part of Vox Ex Machina		
# 																								
# 	Vox Ex Machina is free software: you can redistribute it and/or modify it under the terms		
# 	of the GNU General Public License as published by the Free Software Foundation, either		
# 	version 3 of the license, or any later version.												
# 																								
# 	Vox Ex Machina is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;		
# 	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	
# 	See the GNU General Public License for more details.										
# 																									
# 	You should have received a copy of the GNU General Public License along with 
# 	Vox Ex Machina.	 If not, see http://www.gnu.org/licenses/													
# 																								
# 																									
# 	Copyright 2016 RedShield Security Ltd (www.redshield.co)															
# 																								
# 	Developed by :																				
#		
# 		Graeme Neilson graeme@redshield.co 	
# 																								
# ----------------------------------------------------------------------------------------------
# vem_server OSC UDP Server / Client
#
# Receives filenames of audio files from OSC client and submits to APIs
# Audio files are machine generated samples for speaker recognition / voice verification systems
#
#

import argparse
import math
import sys
import time
import json

from pythonosc import dispatcher
from pythonosc import osc_server
from pythonosc import osc_message_builder
from pythonosc import udp_client

# internal api
import base64
import dynamic
import analysis_2
import os
import tempfile

# voiceit
from voiceit import *

# server and client
global vox_server
global vox_udp
global count
global email 
global password
global voice


def exit_handler(unused_addr, args, localmsg):
    msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
    msg.add_arg("vox> server...exit")
    msg = msg.build()
    vox_udp.send(msg)
    vox_server.shutdown()


def helo_handler(unused_addr, args, localmsg):
    msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
    msg.add_arg("vox> server..ok")
    msg = msg.build()
    vox_udp.send(msg)


def voiceit_user_handler(unused_addr, args, user):
	# TODO: set username adn password here
	if user == 0:
		email = "example@email.com"
		password = "example-password"
	print(email)


def voiceit_auth_handler(unused_addr, args, filename):
	# voiceit authentication attempt voiceit api	
	print("authenticating")
	vox_result = json.loads(voice.authentication(email, password, filename))
	vox_code = vox_result['ResponseCode']
	fileinfo = os.path.split(filename)
	vox_msg = "".join(["vit> ", fileinfo[1], " ", vox_result['Result']])
	
	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)

	
def voiceit_enrol_handler(unused_addr, args, filename):
	# voiceit enrollment attempt voiceit api
	print("enrolling")	
	vox_result = json.loads(voice.createEnrollment(email, password, filename))
	vox_code = vox_result['ResponseCode']
	fileinfo = os.path.split(filename)
	vox_msg = "".join(["vit> ", fileinfo[1], " ", vox_result['Result']])
	
	msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
	msg.add_arg(vox_msg)
	msg = msg.build()
	vox_udp.send(msg)


def internal_handler(unused_addr, args, filename):
	# hackbright internal API 
	# TODO: define wav file for comparison
	template = "example.wav"
	
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

	
def test_handler(unused_addr, args, filename):
    # test OSC comms works
    msg = osc_message_builder.OscMessageBuilder(address = '/vox/server')
    msg.add_arg("vox> server...ack")
    msg = msg.build()
    vox_udp.send(msg)
	
	
if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument("--ip", default="127.0.0.1", help="The IP to listen on")
	parser.add_argument("--port", type=int, default=7678, help="The port to listen on")
	args = parser.parse_args()

	# initialise VoiceIt API 
	voice = VoiceIt()
	# TODO set default username and password
	password = ""
	email = "example@email.com"
	
	# client listening on local ip only
	vox_udp = udp_client.SimpleUDPClient('127.0.0.1', 57120)
	
	# osc addresses that we isten to
	dispatcher = dispatcher.Dispatcher()
	dispatcher.map("/vox/helo", helo_handler, "helo")
	dispatcher.map("/vox/exit", exit_handler, "exit")
	dispatcher.map("/vox/test", test_handler, "test")
	dispatcher.map("/vox/api/internal", internal_handler, "internal")
	dispatcher.map("/vox/api/voiceit/auth", voiceit_auth_handler, "voiceit_auth")
	dispatcher.map("/vox/api/voiceit/user", voiceit_user_handler, "voiceit_user")
	dispatcher.map("/vox/api/voiceit/enrol", voiceit_enrol_handler, "voiceit_enrol")
	
	vox_server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), dispatcher)
	vox_server.serve_forever()
	
