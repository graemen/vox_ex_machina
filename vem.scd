// ----------------------------------------------------------------------------------------------
//   This file is part of Vox Ex Machina - a speaker verification security assessment tool    
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
//   Copyright 2016 RedShield Security Ltd (www.redshield.co)                                    
//                                                                                               
//   Developed by :                                                                              
//       
//       Graeme Neilson graeme@redshield.co  
//                                                                                               
// ----------------------------------------------------------------------------------------------

s = Server.local;
s.recSampleFormat = "int16";
s.recChannels = 2;
s.recHeaderFormat = "WAV";
s.boot;

"=== Vox Ex Machina ===".postln;

s.waitForBoot({


	var synthVox, synthLabel, synthWav, synthSecret;
	var voxBuf;
	var counter = 1;

	var voxFreq = 0;
	var voxMode = -1;
	var voxScale = 1;
	var voxAlpha = 0.55;
	var voxAmp = 4;
	var voxVoice = 0;
	var voxAPI = 0;
	var voxSecret = false;
	var voxSecFreq = 400;

	var voxClean;

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
	var butRanFreq, togRanFreq;
	var butRanScale, togRanScale;
	var butRanAlpha, togRanAlpha;
	var butRanVoice, togRanVoice;
	var sldRanFreq, sldRanScale, sldRanAlpha,sldRanVoice, sldRanSpec, knobSecSpec;
	var sldRanAlphaNum, sldRanFreqNum, sldRanScaleNum;
	var butSecSignal;

	//GUI ////////////////////////////////////////////////////////////////////////////////////////////
	var win;
	var knobVal, knobValNum, knobValLabel, knobValSpec;
	var knobMode,  knobModeNum, knobModeLabel, knobModeSpec, knobModeLegend;
	var knobScale, knobScaleNum, knobScaleLabel, knobScaleSpec;
	var knobAlpha, knobAlphaNum, knobAlphaLabel, knobAlphaSpec;
	var knobVol, knobVolNum, knobVolLabel, knobVolSpec;
	var knobVoxPlay, knobVoxRec, knobSecNum, knobSec;
	var knobVoiceNum, knobVoiceLabel, knobVoiceSpec, knobVoice;
	var knobCounter, knobCounterNum, knobCounterLabel, knobCounterSpec;
	var defaultFont, phraseFont, butFont, statusFont;
	var defaultColor, defaultAlpha, defaultStringColor, defaultBtnColor, defaultBackColor;
	var labVox, labStatus, lineFreq;
	var txtPhrase, txtPhraseLabel, txtStatus;
	var volLabel, volNumber, volSpec, volKnob;
	var listAPI, listAPILabel, sldLabel, listAPIFont, listUserLabel, listUser;


	var runVox = true;
	var modeVox = 0;
	var butPlay, butRecord, butWavPlay, butWavEnrol;

	var yrow1 = 20;

	var yrow2 = 590; // moved to after 6 and before 7

	var yrow3 = 270;
	var yrow4 = 300; //380
	var yrow5 = 440; //518
	var yrow6 = 480; //560

	var yrow7 = 660;
	var yrow8 = 740;
	var xcol1 = 50;
	var xcol2 = 200;
	var xcol3 = 350;
	var xcol4 = 500;
	var xcol5 = 650;
	var xcol6 = 800;
	var xs = 35;
	var ys = 30;
	var szK = 140;
	var szNx = 70;
	var szNy = 25;
	var szSld = 130;

	defaultFont = Font("Mono", 20, bold: true);
	phraseFont = Font("Mono", 20, bold: true);
	butFont = Font("Mono", 24, bold: true);
	statusFont = Font("Mono", 16, bold: false);
	listAPIFont = Font("Mono", 20, bold: false);
	defaultColor = Color.new255(0,0,0);
	defaultBackColor = Color.new255(0,0,0);
	defaultAlpha = 1.0;
	defaultStringColor = Color.green;
	defaultBtnColor = Color.new255(255,0,0);

	Window.closeAll;
	win = Window.new("Vox Ex Machina", Rect(20, 600, 1000, 800));
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


	//Title /////////////////////////////////////////////////////////////////////////////////////
	//labVox = StaticText.new(win, Rect(xcol1, 0, szNx, szNy));
	//labVox.string = "Status";
	//labVox.align = \left;
	//labVox.font = defaultFont;
	//labVox.stringColor = defaultStringColor;

	// Frequency Mode Knob /////////////////////////////////////////////////////////
	knobModeSpec = ControlSpec(-1, 2, 'lin', 1, -1, " mode");
	knobMode = Knob.new(win, Rect(xcol1, yrow4, szK, szK))
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


	knobModeNum = StaticText.new(win, Rect((xcol1+xs), yrow5, szNx, szNy));
	knobModeNum.background = defaultColor;
	knobModeNum.alpha = defaultAlpha;
	knobModeNum.align = \center;
	knobModeNum.string = "off";
	knobModeNum.font = defaultFont;
	knobModeNum.stringColor = defaultStringColor;

	knobModeLabel = StaticText.new(win, Rect(xcol1, yrow3, szK, 25));
	knobModeLabel.string = "Freq Mode";
	knobModeLabel.align = \center;
	knobModeLabel.font = defaultFont;
	knobModeLabel.stringColor = defaultStringColor;

	// Frequency Value Knob /////////////////////////////////////////////////////////
	knobValSpec = ControlSpec(50, 300, 'exp', 1, 100, " Hz");
	knobVal = Knob.new(win, Rect(xcol2, yrow4, szK, szK))
	.action = {arg v;
		var freq = knobValSpec.map(v.value);
		knobValNum.string = freq.round;
		voxFreq = freq;
		// if playing then real time mod of synth
		if(modeVox == 1, synthVox.set(\val, freq));
	};
	knobVal.value = knobValSpec.unmap(knobValSpec.default);

	knobValNum = StaticText.new(win, Rect((xcol2+xs), yrow5, szNx, szNy));
	knobValNum.background = defaultColor;
	knobValNum.alpha = defaultAlpha;
	knobValNum.align = \center;
	knobValNum.string = knobValSpec.default;
	knobValNum.font = defaultFont;
	knobValNum.stringColor = defaultStringColor;

	knobValLabel = StaticText.new(win, Rect(xcol2, yrow3, szK, 25));
	knobValLabel.string = "Freq Hz";
	knobValLabel.align = \center;
	knobValLabel.font = defaultFont;
	knobValLabel.stringColor = defaultStringColor;

	//Connector
	lineFreq = StaticText.new(win, Rect((xcol1+szK-15), yrow3, szK, szNy));
	lineFreq.string = " -- ";
	lineFreq.align = \left;
	lineFreq.font = defaultFont;
	lineFreq.stringColor = defaultStringColor;



	// Time Scale Knob /////////////////////////////////////////////////////////
	knobScaleSpec = ControlSpec(0.5, 2, 'lin', 0.01, 1, " factor");
	knobScale = Knob.new(win, Rect(xcol3, yrow4, szK, szK))
	.action = {arg v;
		var scale = knobScaleSpec.map(v.value);
		knobScaleNum.string = scale;
		voxScale = scale;
		// if playing then real time mod of synth
		if(modeVox == 1, synthVox.set(\scale, scale));
	};
	knobScale.value = knobScaleSpec.unmap(knobScaleSpec.default);

	knobScaleNum = StaticText.new(win, Rect((xcol3+xs), yrow5, szNx, szNy));
	knobScaleNum.background = defaultColor;
	knobScaleNum.alpha = defaultAlpha;
	knobScaleNum.align = \center;
	knobScaleNum.string = knobScaleSpec.default;
	knobScaleNum.font = defaultFont;
	knobScaleNum.stringColor = defaultStringColor;

	knobScaleLabel = StaticText.new(win, Rect(xcol3, yrow3, szK, 25));
	knobScaleLabel.string = "Time Scale";
	knobScaleLabel.align = \center;
	knobScaleLabel.font = defaultFont;
	knobScaleLabel.stringColor = defaultStringColor;

	// Vocal Tract Knob /////////////////////////////////////////////////////////
	knobAlphaSpec = ControlSpec(0.3, 0.7, 'lin', 0.001, 0.55, " Length");
	knobAlpha = Knob.new(win, Rect(xcol4, yrow4, szK, szK))
	.action = {arg v;
		var alpha = knobAlphaSpec.map(v.value);
		knobAlphaNum.string = alpha;
		voxAlpha = alpha;
		// if playing then real time mod of synth
		if(modeVox == 1, synthVox.set(\alpha, alpha));
	};
	knobAlpha.value = knobAlphaSpec.unmap(knobAlphaSpec.default);

	knobAlphaNum = StaticText.new(win, Rect((xcol4+xs), yrow5, szNx, szNy));
	knobAlphaNum.background = defaultColor;
	knobAlphaNum.alpha = defaultAlpha;
	knobAlphaNum.align = \center;
	knobAlphaNum.string = knobAlphaSpec.default;
	knobAlphaNum.font = defaultFont;
	knobAlphaNum.stringColor = defaultStringColor;

	knobAlphaLabel = StaticText.new(win, Rect(xcol4, yrow3, szK, 25));
	knobAlphaLabel.string = "Vocal Tract";
	knobAlphaLabel.align = \center;
	knobAlphaLabel.font = defaultFont;
	knobAlphaLabel.stringColor = defaultStringColor;

	// Randomise buttons /////////////////////////////////////////////////////////////
	butRanFreq = Button(win, Rect(xcol2, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanFreq = butt.value;
		if(butt.value == 1, {voxMode = 1; {knobMode.valueAction = 0.25}.defer(0);});

	});

	butRanScale = Button(win, Rect(xcol3, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanScale = butt.value;
	});

	butRanAlpha = Button(win, Rect(xcol4, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanAlpha = butt.value;
	});

	butRanVoice = Button(win, Rect(xcol5, yrow5, szNy, szNy))
        .states_([
            [" ", Color.black],
            [" ", Color.black, Color.green],
        ])
        .action_({ arg butt;
		togRanVoice = butt.value;
	});

	// Randomise sliders for tuning
    //sldLabel = StaticText.new(win, Rect(xcol1, yrow6, szK, szNy));
	//sldLabel.string = "Random";
	//sldLabel.align = \center;
	//sldLabel.font = defaultFont;
	//sldLabel.stringColor = defaultStringColor;

	sldRanSpec = ControlSpec(0, 0.5, 'lin', 0.01, 0.2);

	sldRanFreq = Slider.new(win, Rect(xcol2, yrow6, szSld, szNy))
	 .action_({
        var range = sldRanSpec.map(sldRanFreq.value);
		ranFreq = Pmeanrand(knobVal.value-range, knobVal.value+range, inf).asStream;
		sldRanFreqNum.string = sldRanSpec.map(sldRanFreq.value);
        });
	sldRanFreq.value = sldRanSpec.unmap(sldRanSpec.default);
	sldRanFreqNum = StaticText.new(win, Rect((xcol2+xs), yrow6+xs, szNx, szNy));
	sldRanFreqNum.background = defaultColor;
	sldRanFreqNum.alpha = defaultAlpha;
	sldRanFreqNum.align = \center;
	sldRanFreqNum.string = sldRanSpec.map(sldRanFreq.value);
	sldRanFreqNum.font = defaultFont;
	sldRanFreqNum.stringColor = defaultStringColor;

	sldRanScale = Slider.new(win, Rect(xcol3, yrow6, szSld, szNy))
	 .action_({
        var range = sldRanSpec.map(sldRanScale.value);
		ranScale = Pmeanrand(knobScale.value-range, knobScale.value+range, inf).asStream;
		sldRanScaleNum.string = sldRanSpec.map(sldRanScale.value);
        });
	sldRanScale.value = sldRanSpec.unmap(sldRanSpec.default);
	sldRanScaleNum = StaticText.new(win, Rect((xcol3+xs), yrow6+xs, szNx, szNy));
	sldRanScaleNum.background = defaultColor;
	sldRanScaleNum.alpha = defaultAlpha;
	sldRanScaleNum.align = \center;
	sldRanScaleNum.string = sldRanSpec.map(sldRanScale.value);
	sldRanScaleNum.font = defaultFont;
	sldRanScaleNum.stringColor = defaultStringColor;

	sldRanAlpha = Slider.new(win, Rect(xcol4, yrow6, szSld, szNy))
	 .action_({
		var range = sldRanSpec.map(sldRanAlpha.value);
		ranAlpha = Pmeanrand(knobAlpha.value-range, knobAlpha.value+range, inf).asStream;
		sldRanAlphaNum.string = sldRanSpec.map(sldRanAlpha.value);
        });
	sldRanAlpha.value = sldRanSpec.unmap(sldRanSpec.default);
	sldRanAlphaNum = StaticText.new(win, Rect((xcol4+xs), yrow6+xs, szNx, szNy));
	sldRanAlphaNum.background = defaultColor;
	sldRanAlphaNum.alpha = defaultAlpha;
	sldRanAlphaNum.align = \center;
	sldRanAlphaNum.string = sldRanSpec.map(sldRanAlpha.value);
	sldRanAlphaNum.font = defaultFont;
	sldRanAlphaNum.stringColor = defaultStringColor;

	//Counter Slider /////////////////////////////////////////////////////////////
	knobCounterSpec = ControlSpec(1, 1000, 'exp', 1, 1);
	knobCounter = Slider.new(win, Rect(xcol1, yrow7, xcol4, 25))
	 .action_({
        knobCounterNum.string_(knobCounterSpec.map(knobCounter.value).asString);
        counter = knobCounterSpec.map(knobCounter.value);
        });

	knobCounterNum = StaticText.new(win, Rect(xcol1, (yrow7+ys), szNx, szNy));
	knobCounterNum.background = defaultColor;
	knobCounterNum.alpha = defaultAlpha;
	knobCounterNum.align = \center;
	knobCounterNum.string = knobCounterSpec.default;
	knobCounterNum.font = defaultFont;
	knobCounterNum.stringColor = defaultStringColor;

	knobCounterLabel = StaticText.new(win, Rect(xcol1, (yrow7-ys), szNx*2, 25));
	knobCounterLabel.string = "Attempts";
	knobCounterLabel.align = \left;
	knobCounterLabel.font = defaultFont;
	knobCounterLabel.stringColor = defaultStringColor;

	knobCounter.value = knobCounterSpec.unmap(knobCounterSpec.default);

	// Vox Play and Record Button /////////////////////////////////////////////////////////
	knobVoxPlay = Button(win, Rect(xcol3, yrow8, szK, xs))
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

	knobVoxRec = Button(win, Rect(xcol4, yrow8, szK, xs))
        .states_([
            ["REC 0", Color.black],
            ["STOP 0", Color.black, Color.red],
        ])
        .action_({ arg butt;
		butt.value.postln;
		if (butt.value == 1, {
			modeVox = 2;
			{txtStatus.setString("vox> sending " ++ counter ++ " ...\n",0)}.defer(0);
		});

	});
	knobVoxRec.font = butFont;

	//Internal / API Selector
	listAPILabel = StaticText.new(win, Rect(xcol5, (yrow2-ys), szK, 25));
	listAPILabel.string = "Target";
	listAPILabel.align = \center;
	listAPILabel.font = defaultFont;
	listAPILabel.stringColor = defaultStringColor;

	listAPI = ListView(win,Rect(xcol5, yrow2, szK, (yrow7-yrow2+ys)))
    .items_([ "-internal", "voiceit" ])
	.font_(defaultFont)
    .background_(Color.white)
    .hiliteColor_(Color.black)
	.selectionMode_(\single)
    .action_({ arg sbs;
		voxAPI = sbs.value;

    });

	//User Selector
	listUserLabel = StaticText.new(win, Rect(xcol6, (yrow2-ys), szK, 25));
	listUserLabel.string = "User";
	listUserLabel.align = \center;
	listUserLabel.font = defaultFont;
	listUserLabel.stringColor = defaultStringColor;

	listUser = ListView(win,Rect(xcol6, yrow2, szK, (yrow7-yrow2+ys)))
	.items_([ "username" ])
	.font_(defaultFont)
    .background_(Color.white)
    .hiliteColor_(Color.black)
	.selectionMode_(\single)
    .action_({ arg sbs;
		oscSend.sendMsg("/vox/api/voiceit/user", sbs.value);

    });


	//Voice Knob /////////////////////////////////////////////////////
	knobVoiceSpec = ControlSpec(0, 5, \lin, 1, 0, "vox");
	knobVoice = Knob.new(win, Rect(xcol5, yrow4, szK, szK))
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

	knobVoiceNum = StaticText.new(win, Rect(xcol5+xs, yrow5, szNx, szNy));
	knobVoiceNum.background = defaultColor;
	knobVoiceNum.alpha = defaultAlpha;
	knobVoiceNum.align = \center;
	knobVoiceNum.string = "awb";
	knobVoiceNum.font = defaultFont;
	knobVoiceNum.stringColor = defaultStringColor;

	knobVoiceLabel = StaticText.new(win, Rect(xcol5, yrow3, szK, 25));
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
		{txtStatus.setString("vox> sample...ok\n",0)}.defer(0);
	};

	// Text fields ///////////////////////////////////////////////////////////////
	txtPhraseLabel = StaticText.new(win, Rect(xcol1, yrow2-ys, szK, 25));
	txtPhraseLabel.string = "Sample";
	txtPhraseLabel.align = \left;
	txtPhraseLabel.font = defaultFont;
	txtPhraseLabel.stringColor = defaultStringColor;

	txtPhrase = TextField(win, Rect(xcol1, yrow2, xcol4, 30));
	txtPhrase.font = phraseFont;
	txtPhrase.string = "Never forget tomorrow is a new day.";
	txtPhrase.action = {arg field;
		synthLabel.value(field.value);
	};

	txtStatus = TextView(win, Rect(50, yrow1, 900, 220));
	txtStatus.editable = false;
	txtStatus.hasVerticalScroller = true;
	txtStatus.autohidesScrollers = false;
	txtStatus.string = "\n";
	txtStatus.font = statusFont;

	// Play a WAV file - replay or enrol //////////////////////////////////////////////////
	//wav file synth player
	SynthDef(\wav, { arg out=0, bufnum=0,  amp=1.0;
		var replay = (PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum))) * amp;
		Out.ar(out, replay);
	}).add;

	synthWav = { arg filename, mode=0;
		b = Buffer.read(s,filename);
		Synth(\wav,[\out, 0, \bufnum, b, \amp, voxAmp]);

		// replay the file till counter is zero
		{
			if (mode == 0,{
				{txtStatus.setString("vox> replay " ++ counter ++ " " ++ filename ++ "\n",0)}.defer(0);
				while({counter > 0},{
					oscSend.sendMsg("/vox/api/voiceit/auth", filename);
					counter = counter - 1;
					wait(1);
					if ( counter < 1, {
						modeVox = 0;
						{butWavPlay.valueAction = 0}.defer(0);
						{txtStatus.setString("vox> wait...\n",0)}.defer(0);
					});
				});
			});

			if (mode == 1,{
				{txtStatus.setString("vox> enrol " ++ counter ++ " " ++ filename ++ "\n",0)}.defer(0);
				oscSend.sendMsg("/vox/api/voiceit/enrol", filename);
				{butWavEnrol.valueAction = 0}.defer(0);
			});

		}.fork;
	};

	butWavPlay = Button(win, Rect(xcol2, yrow8, szK, xs))
        .states_([
            ["REP <", Color.black],
		    ["STOP <", Color.black, Color.red],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			Dialog.openPanel({arg path; synthWav.value(path, 0);});
		});
		});
	butWavPlay.font = butFont;

	butWavEnrol = Button(win, Rect(xcol1, yrow8, szK, xs))
        .states_([
            ["ENR ^", Color.black],
		    ["STOP ^", Color.black, Color.red],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			Dialog.openPanel({arg path; synthWav.value(path, 1)});
		});
		});
	butWavEnrol.font = butFont;

	//Secret Signal Synth  /////////////////////////////////////
	SynthDef(\secret, { arg out=0, freq=10, amp=1.0;
		var secret = (SinOsc.ar(voxSecFreq, 0, 0.2)) * amp;
		Out.ar(out, secret);
	}).add;

	butSecSignal = Button(win, Rect(xcol5, yrow8, szK, xs))
        .states_([
            ["INS ~", Color.black],
		    ["STOP ~", Color.black, Color.green],
        ])
        .action_({ arg butt;
		if (butt.value == 1, {
			voxSecret = true;
		});
		if (butt.value == 0, {
			voxSecret = false;
		});
		});
	butSecSignal.font = butFont;

	// Frequency Value Knob /////////////////////////////////////////////////////////
	knobSecSpec = ControlSpec(1, 30000, 'exp', 1, 10, " Hz");
	knobSec = Knob.new(win, Rect(xcol6+xs, yrow8-ys, szK/2, szK/2))
	.action = {arg v;
		var freq = knobSecSpec.map(v.value);
		knobSecNum.string = freq.round;
		voxSecFreq = freq;
		// if playing then real time mod of synth
		if(modeVox == 1, synthSecret.set(\freq, voxSecFreq));
	};
	knobSec.value = knobSecSpec.unmap(knobSecSpec.default);

	knobSecNum = StaticText.new(win, Rect((xcol6+xs), yrow8+ys, szNx, szNy));
	knobSecNum.background = defaultColor;
	knobSecNum.alpha = defaultAlpha;
	knobSecNum.align = \center;
	knobSecNum.string = knobSecSpec.default;
	knobSecNum.font = defaultFont;
	knobSecNum.stringColor = defaultStringColor;

	// Voice API python server ////////////////////////////////////////
	//TODO: check path to vem_server.py
	apiVoiceStart = {
		c = "/usr/bin/python3 vem_server.py";
		c.unixCmd;
		"osc server started".postln;

	};

	apiVoiceStop = {
		oscSend.sendMsg("/vox/exit", "exit");
	};

	apiVoiceAuth = { arg filename = "";
		i = "/home/graeme/tmp/" ++ o ++ ".wav";
		r = "/home/graeme/tmp/" ++ o ++ "_r.wav";

		//resample file with sox
		c = "sox -S " ++ i ++ " " ++ r ++ " rate -L -s 22050";
		c.systemCmd;

		// do internal comparison of voice files
		if (voxAPI == 0, {
			oscSend.sendMsg("/vox/api/internal", r);
			//{txtStatus.setString("*", 0)}.defer(0);
		});
		// send to VoiceIT api
		if (voxAPI == 1, {
			oscSend.sendMsg("/vox/api/voiceit/auth", r);
			//{txtStatus.setString("*", 0)}.defer(0);
		});

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
		f = "rm /home/graeme/tmp/*";
		f.systemCmd;
	};


	//CODE //////////////////////////////////////////////////////////////////////////////////////////////
	//default label file creation
	{txtStatus.setString("-------------------------------------------\n",0)}.defer(0);
	{txtStatus.setString("VOX EX MACHINA - v1.0 - graeme@redshield.co\n",0)}.defer(0);
	{txtStatus.setString("                                           \n",0)}.defer(0);
	{txtStatus.setString("         X  Troopers Ten Mix  X            \n",0)}.defer(0);
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


	"vox> init....ok".postln;
	{txtStatus.setString("vox> synth...ok\n",0)}.defer(0);

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
			{ modeVox == 1 } {

				// randomisation toggles
				if (togRanFreq == 1,  { {knobVal.valueAction  = ranFreq.next}.defer(0);});
				if (togRanScale == 1, { {knobScale.valueAction = ranScale.next}.defer(0);});
				if (togRanAlpha == 1, { {knobAlpha.valueAction = ranAlpha.next}.defer(0);});
				if (togRanVoice == 1, { {knobVoice.valueAction = ranVoice.next}.defer(0);});

				//play
				s.sync;
				synthSecret = Synth(\secret,[out: 0, freq: voxSecFreq, amp: voxAmp]).run(voxSecret);
				synthVox = Synth(\vox, [bufnum:voxBuf, val:voxFreq, mode:voxMode, scale:voxScale, alpha:voxAlpha, amp:voxAmp, voice:voxVoice] );
				wait(5 * voxScale);

				synthSecret.free;
				synthVox.free;
			}
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

				s.prepareForRecord("/home/graeme/tmp/" ++ o ++ ".wav");
				s.sync;
				//play phrase thru mage synth with random values
				synthSecret = Synth(\secret,[out: 0, freq: voxSecFreq, amp: voxAmp]).run(voxSecret);
				synthVox = Synth(\vox, [bufnum:voxBuf, val:voxFreq, mode:voxMode, scale:voxScale, alpha:voxAlpha, amp:voxAmp, voice:voxVoice] );

				//record
				s.record;
				wait(5);
				s.stopRecording;

				synthSecret.free;
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
	"vox> vox ex machina found her tongue.".postln;
});

