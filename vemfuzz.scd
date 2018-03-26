// ----------------------------------------------------------------------------------------------
//   This file is part of Vox Ex Machina - a speaker verification  and speech recognition
//   security assessment tool.
//
//   Vox Ex Machina is free software: you can redistribute it and/or modify it under the terms
//   of the GNU General Public License as published by the Free Software Foundation, either
//   version 3 of the license, or any later version.
//
//   Vox Ex Machina is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
//   You should have received a copy of the GNU General Public License along with
//   Vox Ex Machina.  If not, see http://www.gnu.org/licenses/
//
//
//   Copyright 2018 lolux productions
//
//   Developed by :
//
//       Graeme Neilson graeme@lolux.net
//
// ----------------------------------------------------------------------------------------------


s = Server.local;
s.recSampleFormat = "int16";
s.recChannels = 2;
s.recHeaderFormat = "WAV";
s.boot;

"=== Vox Ex Machina ===".postln;

s.waitForBoot({


	var synthVox, synthLabel, synthWav, synthTones, synthNoise, synthDTMF;
	var voxBuf;
	var counter = 1;

	var voxFreq = 0;
	var voxMode = -1;
	var voxScale = 1;
	var voxAlpha = 0.55;
	var voxAmp = 4;
	var voxVoice = 0;
	var voxAPI = "internal";
	var voxSecFreq = 0;
	var voxNoiseAmp = 0.0;
	var voxSigSin = false;
	var voxSigNoise = false;
	var voxSigVox = false;

	var voxClean;

	var lenSignal = 0.1;
	var lenSilence = 0.1;

	// OSC server
	var oscSend = NetAddr.new("127.0.0.1", 7678);

	//insert your IPhone/Ipod Touch IP + Send Port here
	var oscSendPhone = NetAddr("10.20.15.66", 58100);

	var oscMsg, oscMsgF, oscMsgM, oscMsgS, oscMsgA, oscMsgX, oscMsgV, oscMsgP, oscMsgR;
	var apiVoiceStart, apiVoiceStop, apiVoiceAuth, apiVoiceListen;

	//randomisation
	var ranFreq = Pmeanrand(0.3, 0.7, inf).asStream;
	var ranScale = Pmeanrand(0.3, 0.7, inf).asStream;
	var ranAlpha = Pmeanrand(0.3, 0.7, inf).asStream;
	var ranVoice = Pmeanrand(0, 1, inf).asStream;
	var ranTone = Pmeanrand(0, 15, inf).asStream;
	var butRanFreq, togRanFreq, butRanScale, togRanScale, butRanAlpha, togRanAlpha, butRanVoice, togRanVoice, butSigSin, butSigNoise, butSigVox;
	var sldRanFreq, sldRanScale, sldRanAlpha,sldRanVoice, sldRanSpec, knobSecSpec, sldRanAlphaNum, sldRanFreqNum, sldRanScaleNum;
	var butSecSignal;

	//GUI ////////////////////////////////////////////////////////////////////////////////////////////
	var win;
	var knobVal, knobValNum, knobValLabel, knobValSpec;
	var knobMode,  knobModeNum, knobModeLabel, knobModeSpec, knobModeLegend;
	var knobScale, knobScaleNum, knobScaleLabel, knobScaleSpec;
	var knobAlpha, knobAlphaNum, knobAlphaLabel, knobAlphaSpec;
	var knobVol, knobVolNum, knobVolLabel, knobVolSpec;
	var knobTones, knobTonesNum, knobTonesLabel, knobTonesSpec;
	var knobVoxPlay, knobVoxRec, knobSecNum, knobSec, knobSecLabel, knobNoiseNum, knobNoise, knobNoiseLabel, knobNoiseSpec;
	var knobVoiceNum, knobVoiceLabel, knobVoiceSpec, knobVoice;
	var knobCounter, knobCounterNum, knobCounterLabel, knobCounterSpec;
	var defaultFont, phraseFont, butFont, statusFont;
	var defaultColor, defaultAlpha, defaultStringColor, defaultBtnColor, defaultBackColor, statusStringColor, statusBackColor;
	var labVox, labStatus, lineFreq, txtPhrase, txtPhraseLabel, txtStatus;
	var volLabel, volNumber, volSpec, volKnob, listAPI, listAPILabel, sldLabel, listAPIFont, listUserLabel, listUser;


	var runVox = true;
	var modeVox = 0;
	var butPlay, butRecord, butWavPlay, butWavEnrol;

	var yrow1 = 20;  // screen output

	var yrow2 = 590; // moved to after 6 and before 7

	var yrow3 = 250; //voice knobs and labels
	var yrow4 = 280;

	var yrow5 = 360; // voice numbers and buttons
	var yrow6 = 390; // voice sliders for rnd

	var yrow7 = 480;
	var yrow8 = 555;

	var yrow9 = 650;
	var yrow10 =725;

	var xcol1 = 50;
	var xcol2 = 150;
	var xcol3 = 250;
	var xcol4 = 350;
	var xcol5 = 450;
	var xcol6 = 550;
	var xcol7 = 650;
	var xcol8 = 750;
	var xcol9 = 850;
	var xcol10 = 950;

	var xs = 15;
	var ys = 30;
	var szK = 70;
	var szNx = 50;
	var szNy = 20;
	var szSld = 70;

	var bluevox_arr = [[1200, 1300], [1200, 1400],[1300, 1400], [1200, 1500],[1300, 1500], [1400, 1500], [1200, 1600], [1300, 1600],[1400, 1500], [1500, 1600], [1200, 1700], [1300, 1700],[1400, 1700], [1500, 1700], [1600, 1700], [800, 1100]];
	var dtmf_arr = [[941, 1336], [697, 1209],[697, 1336], [697, 1477],[770, 1209], [770, 1336], [770, 1477], [852, 1209],[852, 1336], [852, 1477], [697, 1633], [770, 1633],[852, 1633], [941, 1633], [941, 1209], [941, 1477]];
	var ss5_arr = [[700, 900], [700, 1100],[900, 1100], [700, 1300],[900, 1300], [1100, 1300], [700, 1500], [900, 1500],[1100, 1300], [1300, 1500], [700, 1700], [900, 1700],[1100, 1700], [1300, 1700], [1500, 1700], [2400, 2600]];
	var single_arr = [[440,440]];
	var voxTone = dtmf_arr;


	defaultFont = Font("Mono", 12, bold: true);
	phraseFont = Font("Mono", 12, bold: true);
	butFont = Font("Mono", 12, bold: true);
	statusFont = Font("Mono", 10, bold: false);
	listAPIFont = Font("Mono", 10, bold: false);
	defaultColor = Color.new255(0,0,0);
	defaultBackColor = Color.new255(0,0,0);
	defaultAlpha = 1.0;
	defaultStringColor = Color.green;
	defaultBtnColor = Color.new255(255,0,0);
	statusStringColor = Color.new255(0,0,0);
	statusBackColor = Color.new255(200,200,200);

	Window.closeAll;
	win = Window.new("Vox Ex Machina", Rect(0, 0, 1300, 800));
	win.onClose = {
		// stop processing
		runVox=false;
		s.freeAll;
		// stop osc functions and server
		apiVoiceStop.value;
		oscMsg.free;
		oscMsgF.free;
		oscMsgM.free;
		oscMsgS.free;
		oscMsgA.free;
		oscMsgX.free;
		oscMsgV.free;
		oscMsgP.free;
		oscMsgR.free;
		//clean up files
		voxClean.value;
		Window.closeAll;
		"vox> vox ex machina lost her tongue".postln;
	};

	win.front;
	win.background = Color.new255(80,80,80);
	win.alpha = defaultAlpha;



	// Frequency Mode Knob /////////////////////////////////////////////////////////
	knobModeSpec = ControlSpec(-1, 2, 'lin', 1, -1, " mode");
	knobMode = Knob.new(win, Rect(xcol2, yrow4, szK, szK))
	.action = {arg v;
		var mode = knobModeSpec.map(v.value);
		if (mode == -1, {
			knobModeNum.string = "off";
			{butRanFreq.valueAction = 0}.defer(0);
		};);
		if (mode == 0, {knobModeNum.string = "rep"};);
		if (mode == 1, {knobModeNum.string = "add"};);
		if (mode == 2, {knobModeNum.string = "mul"};);
		voxMode = mode;

	};
	knobMode.value = knobModeSpec.unmap(knobModeSpec.default);

	knobModeNum = StaticText.new(win, Rect((xcol2+xs), yrow5, szNx, szNy));
	knobModeNum.background = defaultColor;
	knobModeNum.alpha = defaultAlpha;
	knobModeNum.align = \center;
	knobModeNum.string = "off";
	knobModeNum.font = defaultFont;
	knobModeNum.stringColor = defaultStringColor;

	knobModeLabel = StaticText.new(win, Rect(xcol2, yrow3, szK, 25));
	knobModeLabel.string = "Freq Mode";
	knobModeLabel.align = \center;
	knobModeLabel.font = defaultFont;
	knobModeLabel.stringColor = defaultStringColor;

	// Frequency Value Knob /////////////////////////////////////////////////////////
	knobValSpec = ControlSpec(50, 300, 'exp', 1, 100, " Hz");
	knobVal = Knob.new(win, Rect(xcol3, yrow4, szK, szK))
	.action = {arg v;
		var freq = knobValSpec.map(v.value);
		knobValNum.string = freq.round;
		voxFreq = freq;
		// if playing then real time mod of synth
		if(modeVox == 1, synthVox.set(\val, freq));
	};
	knobVal.value = knobValSpec.unmap(knobValSpec.default);

	knobValNum = StaticText.new(win, Rect((xcol3+xs), yrow5, szNx, szNy));
	knobValNum.background = defaultColor;
	knobValNum.alpha = defaultAlpha;
	knobValNum.align = \center;
	knobValNum.string = knobValSpec.default;
	knobValNum.font = defaultFont;
	knobValNum.stringColor = defaultStringColor;

	knobValLabel = StaticText.new(win, Rect(xcol3, yrow3, szK, 25));
	knobValLabel.string = "Freq";
	knobValLabel.align = \center;
	knobValLabel.font = defaultFont;
	knobValLabel.stringColor = defaultStringColor;


	// Time Scale Knob /////////////////////////////////////////////////////////
	knobScaleSpec = ControlSpec(0.5, 2, 'lin', 0.01, 1, " factor");
	knobScale = Knob.new(win, Rect(xcol4, yrow4, szK, szK))
	.action = {arg v;
		var scale = knobScaleSpec.map(v.value);
		knobScaleNum.string = scale;
		voxScale = scale;
		// if playing then real time mod of synth
		if(modeVox == 1, synthVox.set(\scale, scale));
	};
	knobScale.value = knobScaleSpec.unmap(knobScaleSpec.default);

	knobScaleNum = StaticText.new(win, Rect((xcol4+xs), yrow5, szNx, szNy));
	knobScaleNum.background = defaultColor;
	knobScaleNum.alpha = defaultAlpha;
	knobScaleNum.align = \center;
	knobScaleNum.string = knobScaleSpec.default;
	knobScaleNum.font = defaultFont;
	knobScaleNum.stringColor = defaultStringColor;

	knobScaleLabel = StaticText.new(win, Rect(xcol4, yrow3, szK, 25));
	knobScaleLabel.string = "Time Scale";
	knobScaleLabel.align = \center;
	knobScaleLabel.font = defaultFont;
	knobScaleLabel.stringColor = defaultStringColor;

	// Vocal Tract Knob /////////////////////////////////////////////////////////
	knobAlphaSpec = ControlSpec(0.3, 0.7, 'lin', 0.001, 0.55, " Length");
	knobAlpha = Knob.new(win, Rect(xcol5, yrow4, szK, szK))
	.action = {arg v;
		var alpha = knobAlphaSpec.map(v.value);
		knobAlphaNum.string = alpha;
		voxAlpha = alpha;
		// if playing then real time mod of synth
		if(modeVox == 1, synthVox.set(\alpha, alpha));
	};
	knobAlpha.value = knobAlphaSpec.unmap(knobAlphaSpec.default);

	knobAlphaNum = StaticText.new(win, Rect((xcol5+xs), yrow5, szNx, szNy));
	knobAlphaNum.background = defaultColor;
	knobAlphaNum.alpha = defaultAlpha;
	knobAlphaNum.align = \center;
	knobAlphaNum.string = knobAlphaSpec.default;
	knobAlphaNum.font = defaultFont;
	knobAlphaNum.stringColor = defaultStringColor;

	knobAlphaLabel = StaticText.new(win, Rect(xcol5, yrow3, szK, 25));
	knobAlphaLabel.string = "Vocal Tract";
	knobAlphaLabel.align = \center;
	knobAlphaLabel.font = defaultFont;
	knobAlphaLabel.stringColor = defaultStringColor;

	// Randomise buttons /////////////////////////////////////////////////////////////
	butRanFreq = Button(win, Rect(xcol3, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanFreq = butt.value;
		if(butt.value == 1, {voxMode = 1; {knobMode.valueAction = 0.25}.defer(0);});

	});

	butRanScale = Button(win, Rect(xcol4, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanScale = butt.value;
	});

	butRanAlpha = Button(win, Rect(xcol5, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanAlpha = butt.value;
	});

	butRanVoice = Button(win, Rect(xcol1, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanVoice = butt.value;
	});

	// Randomise sliders for tuning ///////////////////////////////////////////////////
	sldRanSpec = ControlSpec(0, 0.5, 'lin', 0.01, 0.2);

	sldRanFreq = Slider.new(win, Rect(xcol3, yrow6, szSld, szNy))
	 .action_({
        var range = sldRanSpec.map(sldRanFreq.value);
		ranFreq = Pmeanrand(knobVal.value-range, knobVal.value+range, inf).asStream;
		sldRanFreqNum.string = sldRanSpec.map(sldRanFreq.value);
        });
	sldRanFreq.value = sldRanSpec.unmap(sldRanSpec.default);
	sldRanFreqNum = StaticText.new(win, Rect((xcol3+xs-5), yrow6+ys-10, szNx, szNy));
	sldRanFreqNum.background = defaultColor;
	sldRanFreqNum.alpha = defaultAlpha;
	sldRanFreqNum.align = \center;
	sldRanFreqNum.string = sldRanSpec.map(sldRanFreq.value);
	sldRanFreqNum.font = defaultFont;
	sldRanFreqNum.stringColor = defaultStringColor;

	sldRanScale = Slider.new(win, Rect(xcol4, yrow6, szSld, szNy))
	 .action_({
        var range = sldRanSpec.map(sldRanScale.value);
		ranScale = Pmeanrand(knobScale.value-range, knobScale.value+range, inf).asStream;
		sldRanScaleNum.string = sldRanSpec.map(sldRanScale.value);
        });
	sldRanScale.value = sldRanSpec.unmap(sldRanSpec.default);
	sldRanScaleNum = StaticText.new(win, Rect((xcol4+xs-5), yrow6+ys-10, szNx, szNy));
	sldRanScaleNum.background = defaultColor;
	sldRanScaleNum.alpha = defaultAlpha;
	sldRanScaleNum.align = \center;
	sldRanScaleNum.string = sldRanSpec.map(sldRanScale.value);
	sldRanScaleNum.font = defaultFont;
	sldRanScaleNum.stringColor = defaultStringColor;

	sldRanAlpha = Slider.new(win, Rect(xcol5, yrow6, szSld, szNy))
	 .action_({
		var range = sldRanSpec.map(sldRanAlpha.value);
		ranAlpha = Pmeanrand(knobAlpha.value-range, knobAlpha.value+range, inf).asStream;
		sldRanAlphaNum.string = sldRanSpec.map(sldRanAlpha.value);
        });
	sldRanAlpha.value = sldRanSpec.unmap(sldRanSpec.default);
	sldRanAlphaNum = StaticText.new(win, Rect((xcol5+xs-5), yrow6+ys-10, szNx, szNy));
	sldRanAlphaNum.background = defaultColor;
	sldRanAlphaNum.alpha = defaultAlpha;
	sldRanAlphaNum.align = \center;
	sldRanAlphaNum.string = sldRanSpec.map(sldRanAlpha.value);
	sldRanAlphaNum.font = defaultFont;
	sldRanAlphaNum.stringColor = defaultStringColor;

	//Counter Slider /////////////////////////////////////////////////////////////
	knobCounterSpec = ControlSpec(1, 1000, 'exp', 1, 1);
	knobCounter = Slider.new(win, Rect(xcol9+szK, yrow6, 300, szNy))
	 .action_({
        knobCounterNum.string_(knobCounterSpec.map(knobCounter.value).asString);
        counter = knobCounterSpec.map(knobCounter.value);
        });

	knobCounterNum = StaticText.new(win, Rect(xcol9+szK, (yrow6+ys-10), szNx, szNy));
	knobCounterNum.background = defaultColor;
	knobCounterNum.alpha = defaultAlpha;
	knobCounterNum.align = \center;
	knobCounterNum.string = knobCounterSpec.default;
	knobCounterNum.font = defaultFont;
	knobCounterNum.stringColor = defaultStringColor;

	knobCounterLabel = StaticText.new(win, Rect(xcol9, (yrow6), szK, 25));
	knobCounterLabel.string = "Attempts";
	knobCounterLabel.align = \left;
	knobCounterLabel.font = defaultFont;
	knobCounterLabel.stringColor = defaultStringColor;

	knobCounter.value = knobCounterSpec.unmap(knobCounterSpec.default);

	// Vox Play and Record Button /////////////////////////////////////////////////////////
	knobVoxPlay = Button(win, Rect(xcol5, yrow10, szK, xs))
        .states_([
            ["PLAY >", Color.black],
            ["STOP >", Color.black, Color.green],
        ])
        .action_({ arg butt;
		butt.value.postln;
		modeVox = butt.value;
		if (modeVox == 1, {
			"vox> play".postln;
			{txtStatus.setString("vox> playing...\n",0)}.defer(0);
		});
	});
	knobVoxPlay.font = butFont;

	knobVoxRec = Button(win, Rect(xcol8, yrow10, szK, xs))
        .states_([
            ["REC 0", Color.black],
            ["STOP 0", Color.black, Color.red],
        ])
        .action_({ arg butt;
		butt.value.postln;
		if (butt.value == 1, {
			modeVox = 2;
			{txtStatus.setString("vox> sending: " ++ counter ++ "\n",0)}.defer(0);
		});

	});
	knobVoxRec.font = butFont;

	//Internal / API Selector ////////////////////////////////////////////////////
	listAPILabel = StaticText.new(win, Rect(xcol8, (yrow4-ys), szK, 25));
	listAPILabel.string = "Target API";
	listAPILabel.align = \center;
	listAPILabel.font = defaultFont;
	listAPILabel.stringColor = defaultStringColor;

	listAPI = ListView(win,Rect(xcol8, yrow4, szK, 150))
	.items_([ "internal", "voiceit", "msazure" ])
	.font_(defaultFont)
    .background_(Color.white)
    .hiliteColor_(Color.grey)
	.selectedStringColor_(Color.green)
	.selectionMode_(\single)
    .action_({ arg sbs;
	voxAPI = listAPI.items[sbs.value];
		{txtStatus.setString("vox> api: " ++ voxAPI ++ "\n",0)}.defer(0);

    });

	//User Field for user id entry
	listUserLabel = StaticText.new(win, Rect(xcol9, yrow4, szK, 25));
	listUserLabel.string = "User";
	listUserLabel.align = \left;
	listUserLabel.font = defaultFont;
	listUserLabel.stringColor = defaultStringColor;

	listUser = TextField(win, Rect(xcol9+szK, yrow4, 300, 25));
	listUser.font = phraseFont;
	listUser.string = " ";
	listUser.action = {arg field;
		oscSend.sendMsg("/vox/api/user", field.value);
		{txtStatus.setString("vox> user: " ++ field.value ++ "\n",0)}.defer(0);
	};



	//Voice Knob /////////////////////////////////////////////////////
	knobVoiceSpec = ControlSpec(0, 5, \lin, 1, 0, "vox");
	knobVoice = Knob.new(win, Rect(xcol1, yrow4, szK, szK))
	.action = {arg v;
		var voice = knobVoiceSpec.map(v.value);
		if (voice == 0, {knobVoiceNum.string = "awb";});
		if (voice == 1, {knobVoiceNum.string = "bdl";});
		if (voice == 2, {knobVoiceNum.string = "clb";});
		if (voice == 3, {knobVoiceNum.string = "jmk";});
		if (voice == 4, {knobVoiceNum.string = "rms";});
		if (voice == 5, {knobVoiceNum.string = "slt";});
		voxVoice = voice;
		if(modeVox == 1, {synthVox.set(\voice, voice)};)
	};
	knobVoice.value = knobVoiceSpec.unmap(knobVoiceSpec.default);

	knobVoiceNum = StaticText.new(win, Rect(xcol1+xs, yrow5, szNx, szNy));
	knobVoiceNum.background = defaultColor;
	knobVoiceNum.alpha = defaultAlpha;
	knobVoiceNum.align = \center;
	knobVoiceNum.string = "awb";
	knobVoiceNum.font = defaultFont;
	knobVoiceNum.stringColor = defaultStringColor;

	knobVoiceLabel = StaticText.new(win, Rect(xcol1, yrow3, szK, 25));
	knobVoiceLabel.string = "Voice";
	knobVoiceLabel.align = \center;
	knobVoiceLabel.font = defaultFont;
	knobVoiceLabel.stringColor = defaultStringColor;

	//Amplification /////////////////////////////////////////////////////
	volSpec = ControlSpec(0, 11, \lin, 0.1, 4, "dB");
	volKnob = Knob.new(win, Rect(xcol6, yrow4, szK, szK))
	.action = {arg v;
		var vol = volSpec.map(v.value);
		volNumber.string = vol;
		voxAmp = vol;
		if(modeVox == 1, {synthVox.set(\amp, vol)};)
	};
	volKnob.value = volSpec.unmap(volSpec.default);

	volNumber = StaticText.new(win, Rect((xcol6+xs), yrow5, szNx, szNy));
	volNumber.background = defaultColor;
	volNumber.alpha = defaultAlpha;
	volNumber.align = \center;
	volNumber.string = volSpec.default;
	volNumber.font = defaultFont;
	volNumber.stringColor = defaultStringColor;

	volLabel = StaticText.new(win, Rect(xcol6, yrow3, szK, 25));
	volLabel.string = "Volume";
	volLabel.align = \center;
	volLabel.font = defaultFont;
	volLabel.stringColor = defaultStringColor;

	// Create a label file from text string /////////////////////////////////////
	synthLabel = { arg phrase = "Never forget tomorrow is a new day.";
		voxBuf.notNil.if { voxBuf.free; };
		"new label:".postln;
		SCMage.labelBuf(phrase, { |buf|
			voxBuf = buf;
		});
		{txtStatus.setString("vox> sample: ok\n",0)}.defer(0);
	};

	// Phrase  ///////////////////////////////////////////////////////////////
	txtPhraseLabel = StaticText.new(win, Rect(xcol9, yrow5-ys, szK, 25));
	txtPhraseLabel.string = "Speech";
	txtPhraseLabel.align = \left;
	txtPhraseLabel.font = defaultFont;
	txtPhraseLabel.stringColor = defaultStringColor;

	txtPhrase = TextField(win, Rect(xcol9+szK, yrow5-ys, 300, 25));
	txtPhrase.font = phraseFont;
	txtPhrase.string = "Never forget tomorrow is a new day.";
	txtPhrase.action = {arg field;
		synthLabel.value(field.value);
	};

	// Status Console ////////////////////////////////////////////////////////
	txtStatus = TextView(win, Rect(xcol1, yrow1, 1200, 220));
	txtStatus.editable = false;
	txtStatus.hasVerticalScroller = true;
	txtStatus.autohidesScrollers = false;
	txtStatus.string = "\n";
	txtStatus.font_(statusFont);
	txtStatus.stringColor_(statusStringColor);
	txtStatus.background_(statusBackColor);

	// Play a WAV file - replay or enrol//////////////////////////////////////////////////
	//wav file synth player
	SynthDef(\wav, { arg out=0, bufnum=0,  amp=1.0;
		var replay = (PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum))) * amp;
		Out.ar(out, replay);
	}).add;

	synthWav = { arg filename, mode=0, api;
		b = Buffer.read(s,filename);
		Synth(\wav,[\out, 0, \bufnum, b, \amp, voxAmp]);

		// replay the file till counter is zero
		{
			//replay authentication
			if (mode == 0,{
				var oscurl = "/vox/api/auth/" ++ api;
				{txtStatus.setString("vox> replay: " ++ counter ++ " " ++ filename ++ "\n",0)}.defer(0);
				while({counter > 0},{
					oscSend.sendMsg(oscurl, filename);
					counter = counter - 1;
					wait(1);
					if ( counter < 1, {
						modeVox = 0;
						{butWavPlay.valueAction = 0}.defer(0);
						{txtStatus.setString("vox> wait...\n",0)}.defer(0);
					});
				});
			});
			// replay enrollment once
			if (mode == 1,{
				var oscurl = "/vox/api/enrol/" ++ api;
				{txtStatus.setString("vox> enrol: " ++ filename ++ "\n",0)}.defer(0);
				oscSend.sendMsg(oscurl, filename);
				{butWavEnrol.valueAction = 0}.defer(0);
			});

		}.fork;
	};

	butWavPlay = Button(win, Rect(xcol6, yrow10, szK, xs))
        .states_([
            ["REP <", Color.black],
		    ["STOP <", Color.black, Color.red],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			Dialog.openPanel({arg path; synthWav.value(path, 0, voxAPI);});
		});
		});
	butWavPlay.font = butFont;

	butWavEnrol = Button(win, Rect(xcol7, yrow10, szK, xs))
        .states_([
            ["ENR ^", Color.black],
		    ["STOP ^", Color.black, Color.red],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			Dialog.openPanel({arg path; synthWav.value(path, 1, voxAPI)});
		});
		});
	butWavEnrol.font = butFont;

	//Tones Knob /////////////////////////////////////////////////////
	knobTonesSpec = ControlSpec(0, 3, \lin, 1, 0, "tone");
	knobTones = Knob.new(win, Rect(xcol1, yrow7, szK, szK))
	.action = {arg v;
		var tone = knobTonesSpec.map(v.value);
		if (tone == 0, {knobTonesNum.string = "single";
			voxTone = single_arr});
		if (tone == 1, {knobTonesNum.string = "dtmf";
			voxTone = dtmf_arr});
		if (tone == 2, {knobTonesNum.string = "ss5";
			voxTone = ss5_arr});
		if (tone == 3, {knobTonesNum.string = "bluevox";
			voxTone = bluevox_arr});
		synthTones.set(\tones, voxTone)
	};
	knobTones.value = knobTonesSpec.unmap(knobTonesSpec.default);

	knobTonesNum = StaticText.new(win, Rect(xcol1+xs, yrow8, szNx, szNy));
	knobTonesNum.background = defaultColor;
	knobTonesNum.alpha = defaultAlpha;
	knobTonesNum.align = \center;
	knobTonesNum.string = "single";
	knobTonesNum.font = defaultFont;
	knobTonesNum.stringColor = defaultStringColor;

	knobTonesLabel = StaticText.new(win, Rect(xcol1, yrow7-ys, szK, 25));
	knobTonesLabel.string = "Tones";
	knobTonesLabel.align = \center;
	knobTonesLabel.font = defaultFont;
	knobTonesLabel.stringColor = defaultStringColor;

	//Tones Signal Synth  ///////////////////////////////////////////////////////////////////////////

	SynthDef(\tones, { arg tonearr = bluevox_arr, number = 0, mul = 1, pan = 0, out = 0, gate = 1, att = 0.001, decay = 0.001;
		var dtmf, env, freqs;
		freqs = Select.kr(number, tonearr);
		dtmf = SinOsc.ar(freqs, 0, mul);
		dtmf = Mix.new(dtmf)*0.5;
		env = EnvGen.ar(Env.asr(att, 1, decay), gate, doneAction: 2);
		dtmf = dtmf * env;
		dtmf = Pan2.ar(dtmf, pan);
		Out.ar(out, dtmf)
	}).add;


	//Noise Synth  /////////////////////////////////////////////////////////////////////////////////
	SynthDef(\noise, { arg out=0, amp=0;
		var noise = (WhiteNoise.ar(amp));
		Out.ar(out, noise);
	}).add;

	butSigVox = Button(win, Rect(xcol1-xs, yrow3, szNy, szNy))
        .states_([
            [" ", Color.black, Color.red],
		    [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			voxSigVox = true;
		});
		if (butt.value == 0, {
			voxSigVox = false;
		});
		});

	butSigSin = Button(win, Rect(xcol1-xs, yrow7-ys, szNy, szNy))
        .states_([
            [" ", Color.black, Color.red],
		    [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			voxSigSin = true;
		});
		if (butt.value == 0, {
			voxSigSin = false;
		});
		});

	butSigNoise = Button(win, Rect(xcol1-xs, yrow9-ys, szNy, szNy))
        .states_([
            [" ", Color.black, Color.red],
		    [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			voxSigNoise = true;
		});
		if (butt.value == 0, {
			voxSigNoise = false;
		});
		});


	// Tones Frequency Value Knob ///////////////////////////////////////////////
	knobSecSpec = ControlSpec(1, 30000, 'exp', 1, 1, " Hz");
	knobSec = Knob.new(win, Rect(xcol2, yrow7, szK, szK))
	.action = {arg v;
		var freq = knobSecSpec.map(v.value);
		knobSecNum.string = freq.round;
		voxSecFreq = freq;
		// if playing then real time mod of synth
		if(modeVox == 1, synthTones.set(\freq, voxSecFreq));
	};
	knobSec.value = knobSecSpec.unmap(knobSecSpec.default);

	knobSecNum = StaticText.new(win, Rect((xcol2+xs), yrow8, szNx, szNy));
	knobSecNum.background = defaultColor;
	knobSecNum.alpha = defaultAlpha;
	knobSecNum.align = \center;
	knobSecNum.string = knobSecSpec.default;
	knobSecNum.font = defaultFont;
	knobSecNum.stringColor = defaultStringColor;

	knobSecLabel = StaticText.new(win, Rect(xcol2, yrow7-ys, szK, 25));
	knobSecLabel.string = "Freq";
	knobSecLabel.align = \center;
	knobSecLabel.font = defaultFont;
	knobSecLabel.stringColor = defaultStringColor;


	//White Noise Knob /////////////////////////////////////////////////////////
	knobNoiseSpec = ControlSpec(0, 1.0, 'lin', 0.01, 0, " ");
	knobNoise = Knob.new(win, Rect(xcol1, yrow9, szK, szK))
	.action = {arg v;
		var noise = knobNoiseSpec.map(v.value);
		knobNoiseNum.string = noise;
		voxNoiseAmp = noise;
		// if playing then real time mod of synth
		if(modeVox == 1, synthNoise.set(\amp, voxNoiseAmp));

	};
	knobNoise.value = knobNoiseSpec.unmap(knobNoiseSpec.default);

	knobNoiseNum = StaticText.new(win, Rect((xcol1+xs), yrow10, szNx, szNy));
	knobNoiseNum.background = defaultColor;
	knobNoiseNum.alpha = defaultAlpha;
	knobNoiseNum.align = \center;
	knobNoiseNum.string = knobNoiseSpec.default;
	knobNoiseNum.font = defaultFont;
	knobNoiseNum.stringColor = defaultStringColor;

	knobNoiseLabel = StaticText.new(win, Rect(xcol1, yrow9-ys, szK, 25));
	knobNoiseLabel.string = "Noise";
	knobNoiseLabel.align = \center;
	knobNoiseLabel.font = defaultFont;
	knobNoiseLabel.stringColor = defaultStringColor;

	//TODO: Listen Controls ///////////////////////////////////////////////////////////////////////
	//
	//turn on microphone

	//select file to save responses

	//send file to python speech recognition server


	// Voice API python server ////////////////////////////////////////
	apiVoiceStart = {
		c = "/usr/bin/python3 /Users/graeme/Code/vox/vem_server.py";
		c.unixCmd;
		"osc server started".postln;
	};

	apiVoiceStop = {
		oscSend.sendMsg("/vox/exit", "exit");
	};

	apiVoiceAuth = { arg filename = "";

		i = "/Users/graeme/tmp/" ++ o ++ ".wav";
		r = "/Users/graeme/tmp/" ++ o ++ "_r.wav";
		u = "/vox/api/auth/" ++ voxAPI;

		//Resample using sox: different apis require different sample rates
		if(voxAPI == "voiceit",
			{

				c = "sox -S " ++ i ++ " " ++ r ++ " rate -L -s 22050";
				c.systemCmd;
			}
		);

		if(voxAPI == "msazure",
			{
				c = "sox -S " ++ i ++ " " ++ r ++ " channels 1 rate -L -s 16000";
				c.systemCmd;
			}
		);

		oscSend.sendMsg(u, r);
		u.postln;
		//test message get ack from python server
		//oscSend.sendMsg("/vox/test", r);
	};

	apiVoiceListen = {
		// create the OSC receivers
		// messages from python server that communicates with the APIs
		oscMsg = OSCFunc({ arg msg, time, addr, recvPort; {txtStatus.setString(msg[1] ++ "\n",0)}.defer(0); }, '/vox/server');
		"osc listener started".postln;

		// messages from external osc player for remote control
		oscMsgF = OSCFunc({ arg msg, time, addr, recvPort; { knobVal.valueAction = msg[1]}.defer(0); }, '/vox/freq');
		oscMsgM = OSCFunc({ arg msg, time, addr, recvPort; { knobMode.valueAction = msg[1]}.defer(0); }, '/vox/mode');
		oscMsgS = OSCFunc({ arg msg, time, addr, recvPort; { knobScale.valueAction = msg[1]}.defer(0);}, '/vox/scale');
		oscMsgA = OSCFunc({ arg msg, time, addr, recvPort; { knobAlpha.valueAction = msg[1]}.defer(0); }, '/vox/alpha');
		oscMsgX = OSCFunc({ arg msg, time, addr, recvPort; { knobVoice.valueAction = msg[1]}.defer(0); }, '/vox/voice');
		oscMsgV = OSCFunc({ arg msg, time, addr, recvPort; { volKnob.valueAction = msg[1]}.defer(0); }, '/vox/vol');
		oscMsgP = OSCFunc({ arg msg, time, addr, recvPort; { knobVoxPlay.valueAction = msg[1]}.defer(0); }, '/vox/play');
		oscMsgR = OSCFunc({ arg msg, time, addr, recvPort; { knobVoxRec.valueAction = msg[1]}.defer(0); }, '/vox/rec');
		oscMsgR = OSCFunc({ arg msg, time, addr, recvPort; { knobCounter.valueAction = msg[1]}.defer(0); }, '/vox/counter');

	};


	// clean up files ////////////////////////////////////
	voxClean = {
		f = "rm /Users/graeme/tmp/*";
		f.systemCmd;
	};


	//CODE //////////////////////////////////////////////////////////////////////////////////////////////
	//default label file creation
	{txtStatus.setString("-------------------------------------------\n",0)}.defer(0);
	{txtStatus.setString("VOX EX MACHINA - v2.0 - graeme@lolux.net   \n",0)}.defer(0);
	{txtStatus.setString("                                           \n",0)}.defer(0);
	{txtStatus.setString("-------------------------------------------\n",0)}.defer(0);

	synthLabel.value;

	//start python server for voice api comms

	apiVoiceStart.value;
	apiVoiceListen.value;

	//make sure previous  3 operations complete
	wait(5);
	oscSend.sendMsg("/vox/helo", "helo");

	//mage synth definition
	SynthDef(\vox, {arg outbus, bufnum = voxBuf, val = 0, mode = -1, scale = 1, alpha = 0.55, amp = 1.0, voice = 0;
		var mage;
		mage = (SCMage.ar(bufnum: voxBuf, freqValue: val, freqMode: mode, timeScale: scale, alpha: alpha, voiceNum: voice) ! 2) * amp;
		Out.ar(outbus, mage);
	}).add;


	"vox> init...".postln;
	{txtStatus.setString("vox> synths: ok\n",0)}.defer(0);
	{txtStatus.setString("vox> ready\n",0)}.defer(0);
    // fork this block
	{

		//main vem loop
		{runVox}.while({


			//play phrase thru mage synth
			v = case
			{ modeVox == 0 } {
				wait(1);
				{counter = knobCounterSpec.map(knobCounter.value);}.defer(0);

			}
			// play - live fuzzing / testing
			{ modeVox == 1 } {

				// randomisation toggles
				if (togRanFreq == 1,  { {knobVal.valueAction  = ranFreq.next}.defer(0);});
				if (togRanScale == 1, { {knobScale.valueAction = ranScale.next}.defer(0);});
				if (togRanAlpha == 1, { {knobAlpha.valueAction = ranAlpha.next}.defer(0);});
				if (togRanVoice == 1, { {knobVoice.valueAction = ranVoice.next}.defer(0);});
				{knobToneNum.valueAction = ranTone.next}.defer(0);

				//play
				s.sync;
				synthTones = Synth(\tones,[\tonearr, voxTone, \number, toneNum]).run(voxSigSin);
				synthNoise = Synth(\noise, [\amp, voxNoiseAmp]).run(voxSigNoise);
				synthVox = Synth(\vox, [bufnum:voxBuf, val:voxFreq, mode:voxMode, scale:voxScale, alpha:voxAlpha, amp:voxAmp, voice:voxVoice]).run(voxSigVox);

				// TODO make sure entire sample is played (should get lenght of sample....)
				if (voxSigVox == true, { wait(4 * voxScale) } );
				// wait only 1000ms betweeen tones (change to knob value)
				wait(lenSignal);

				synthTones.free;
				synthNoise.free;
				synthVox.free;

				//time between signals
				wait(lenSilence);

			}
			// record - api testing for speach verification
			{ modeVox == 2 } {

				// randomisation toggles
				if (togRanFreq == 1,  { {knobVal.valueAction  = ranFreq.next}.defer(0);});
				if (togRanScale == 1, { {knobScale.valueAction = ranScale.next}.defer(0);});
				if (togRanAlpha == 1, { {knobAlpha.valueAction = ranAlpha.next}.defer(0);});
				if (togRanVoice == 1, { {knobVoice.valueAction = ranVoice.next}.defer(0);});

				//filename for recording timestamp and parameters,
				o = (Date.getDate).stamp ++ "_F" ++ voxFreq   ++ "_S" ++ (voxScale*100) ++ "_T" ++ (voxAlpha*100) ++ "_V" ++ voxVoice;

				//"vox> recording".postln;
				//{txtStatus.setString("vox> rec: " ++ o ++ ".wav\n",0)}.defer(0);

				s.prepareForRecord("/Users/graeme/tmp/" ++ o ++ ".wav");
				s.sync;
				//play phrase thru mage synth with random values
				synthTones = Synth(\tones,[\tonearr, voxTone, \number, ranTone.next]).run(voxSigSin);
				synthNoise = Synth(\noise, [\amp, voxNoiseAmp]).run(voxSigNoise);
				synthVox = Synth(\vox, [bufnum:voxBuf, val:voxFreq, mode:voxMode, scale:voxScale, alpha:voxAlpha, amp:voxAmp, voice:voxVoice]).run(voxSigVox);

				//record
				s.record;
				wait(5);
				s.stopRecording;

				synthTones.free;
				synthNoise.free;
				synthVox.free;

				//python voice API call
				apiVoiceAuth.value(o);

				counter = counter - 1;
				counter.value.postln;

			    if ( counter < 1, {
					modeVox = 0;
					{knobVoxRec.valueAction = 0}.defer(0);
					//{txtStatus.setString("vox> done\n",0)}.defer(0);
				})
			}

		});
	}.fork;
	"vox> vox ex machina found her voice.".postln;
});

