
Server.default = Server.internal;
s.boot;
// MIDI startup: to connect to all the midi devices
MIDIClient.init;
MIDIIn.connectAll;
(

//GUI
var s1, s2;
var left = 0; var top = 0; var alessis;
var dict;
//////////////////////////////////////
var barr;
var keyarr;
var key2arr;
var knobarr;
var adgBArr;
var bindArr;
var playArr;
var boolLoop = false;
//keynums is for the physical keyboard keys
var keyNums = Array.newClear(74-48);
var basepath = "C:/Users/vivek/Documents/MusicProj/*";
b = basepath.pathMatch.collect{|val| Buffer.read(s,val) };
b.postln;

//offset to be used with the octave button
~offset = 0;
//offset for the pad
~padOffset = 0;


////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////SYNTH DEFSSSSSSSSSSS?////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

SynthDef(\mrostinato,{|out= 0 freq = 440 amp = 0.1 gate=1 lforate = 10 lfowidth= 0.5 pan = 0.0|

	var lfo, pulse, filter, env;

	lfo = LFTri.kr(lforate,Rand(0,2.0)!3);

	pulse = Pulse.ar(freq*[1,1.01,0.5],lfo*lfowidth+0.5);

	env = EnvGen.ar(Env.adsr(0.01,0.05,0.5,0.1),gate,doneAction:2);

	Out.ar(out,Pan2.ar(Mix(pulse)*env*amp,pan));

}).add;

SynthDef(\plucking, {arg amp = 0.1, freq = 440, decay = 5, gate = 1, coef = 0.1;

var env, snd;
env = EnvGen.kr(Env.linen(0, decay, 0),gate, doneAction: 2);
snd = Pluck.ar(
        in: WhiteNoise.ar(amp),
        trig: Impulse.kr(0),

        maxdelaytime: 0.1,
        delaytime: freq.reciprocal,
        decaytime: decay,
        coef: coef);
    Out.ar(0, [snd, snd]);
}).add;

SynthDef(\bassfoundation,{|out= 0 freq = 440 amp = 0.1 gate=1 cutoff= 1000 rq=0.5 pan=0.0|

	var osc, filter, env, filterenv;

	osc = Saw.ar(freq);

	filterenv = EnvGen.ar(Env.adsr(0.0,0.5,0.2,0.2),gate,doneAction:2);
	filter =  RLPF.ar(osc,cutoff*filterenv+100,rq);

	env = EnvGen.ar(Env.adsr(0.01,0.0,0.9,0.05),gate,doneAction:2);

	Out.ar(out,Pan2.ar(filter*env*amp*2,pan));

}).add;

SynthDef(\sampleplay,{|out= 0 bufnum = 0 amp = 0.1 gate=1 pan = 0.0|

	var playbuf, env;

	playbuf = PlayBuf.ar(1,bufnum);

	env = EnvGen.ar(Env.adsr(0.0,0.0,9.0,0.1),gate,doneAction:2);

	Out.ar(out,Pan2.ar(playbuf*env*amp,pan));

}).add;

SynthDef(\prophet5pwmstrings,{|out= 0 freq = 440 amp = 1.0 gate=1 lforate = 10 lfowidth= 0.5 cutoff= 12000 rq=0.5 pan = 0.0|

	var lfo, pulse, filter, env;

	lfo = LFTri.kr(lforate*[1,1.01],Rand(0,2.0)!2);

	pulse = Pulse.ar(freq*[1,1.01],lfo*lfowidth+0.5);

	filter = RLPF.ar(pulse,cutoff,rq);

	env = EnvGen.ar(Env.adsr(0.01,0.0,1.0,0.5),gate,doneAction:2);

	Out.ar(out,Pan2.ar(Mix(filter)*env*amp*0.5,pan));

}).add;

SynthDef(\werkit,{|out= 0 freq = 440 amp = 0.1 gate=1 cutoff= 100 rq=0.1 pan=0.0|

	var source, filter, env;

	source = WhiteNoise.ar;

	filter = BLowPass4.ar(source,freq,rq)*0.3;

	//env = EnvGen.ar(Env.adsr(0.01,0.0,1.0,0.1),gate,doneAction:2);
	//no gate, fixed envelope size
	env = EnvGen.ar(Env([0,1,0.5,0.0],[0.02,0.1,0.1]),doneAction:2);

	Out.ar(out,Pan2.ar((0.7*filter+(0.3*filter.distort))*env*amp,pan));

}).add;

SynthDef(\laserbeam,{|out= 0 freq = 440 amp = 0.1 attackTime= 0.04 gate=1 pan=0.0|

	var osc1, freqenv, ampenv;

	freqenv = EnvGen.ar(Env([4,0.5,1,1],[attackTime,0.01,1.0]));

	osc1 = LFTri.ar(freq*freqenv);

	//env = EnvGen.ar(Env.adsr(0.01,0.0,1.0,0.1),gate,doneAction:2);
	//no gate, fixed envelope size
	ampenv = EnvGen.ar(Env([0,1,0.5,0.0],[0.02,0.2,0.1]),doneAction:2);

	Out.ar(out,Pan2.ar(osc1*ampenv*amp,pan));

}).add;

SynthDef(\basshighend,{|out= 0 freq = 440 amp = 0.1 gate=1 cutoff= 3000 rq=0.1 drive = 2.0 pan=0.0|

	var osc, filter, env, filterenv;
	var ab;

	//osc = Mix(VarSaw.ar(freq*[0.25,1,1.5],Rand(0.0,1.0)!3,0.9,[0.5,0.4,0.1]));
	osc = Mix(Saw.ar(freq*[0.25,1,1.5],[0.5,0.4,0.1]));
	//osc = Mix(DPW4Saw.ar(freq*[0.25,1,1.5],[0.5,0.4,0.1]));
	filterenv = EnvGen.ar(Env.adsr(0.0,0.5,0.2,0.2),gate,doneAction:2);
	filter =  RLPF.ar(osc,cutoff*filterenv+100,rq);

 	//distortion
 	//filter = filter.distort.softclip;

	ab = abs(filter);
 	filter = (filter*(ab + drive)/(filter ** 2 + (drive - 1) * ab + 1));

	//remove low end
	filter = BLowShelf.ar(filter,300,1.0,-12);
	//dip at 1600Hz
	filter = BPeakEQ.ar(filter,1600,1.0,-6);

	env = EnvGen.ar(Env.adsr(0.01,0.0,0.9,0.05),gate,doneAction:2);

	Out.ar(out,Pan2.ar(filter*env*amp*2,pan));

}).add;

SynthDef(\synchronicity,{|out= 0 freq = 440 amp = 0.1 gate=1 cutoff=8000 rq=0.2 pan=0.0|

	var pulse, filter, env, slavefreq;

	slavefreq = EnvGen.ar(Env([1,5,1],[0.04,0.9]))*freq;

	pulse = SyncSaw.ar(freq,slavefreq);

	filter = BLowPass.ar(pulse,cutoff,rq);

	env = EnvGen.ar(Env.adsr(0.01,0.0,1.0,0.1),gate,doneAction:2);

	Out.ar(out,Pan2.ar(filter*env*amp,pan));

}).add;
SynthDef(\help_mdapiano, { |out=0, freq=440, gate=1|
    var son = MdaPiano.ar(freq, gate, release: 0.9, stereo: 0.3, sustain: 0);
    DetectSilence.ar(son, 0.01, doneAction:2);
    Out.ar(out, son * 0.1);
}).add;

~instrumentArray = [\mrostinato, \plucking, \bassfoundation, \help_mdapiano,
	\werkit, \laserbeam, \basshighend, \synchronicity
];

////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////Pattern Time//////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

bindArr = Array.fill(b.size, {arg i;
	Pbind(\instrument,\sampleplay,
		\bufnum, b[i],
		\amp, 0.25)});
bindArr.postln;
playArr = Array.newClear(bindArr.size);

// connect to all midi ports
MIDIIn.connectAll;

w = Window.new("Alessis V125", Rect(0, 0, 2360,1240));
s1 = Slider.new(w,Rect(90,90,100,300));
s2 = Slider.new(w,Rect(280,90,100,300));

/////////////////////PAD ARRAY
barr = Array.fill(16, {arg i;
		if (i-1%4 == 3, {top = top + 150});
		if (i+1%4 == 1, {left = 0}, {left = left + 150});
	//left.postln;
	//top.postln;
	Button(w, Rect(30+left,375+top,125,125)).states =
	[["released", Color.white, Color.grey],
		["low", Color.white, Color.blue],
		["medium", Color.white, Color.yellow],
		["high", Color.white, Color.red]]});
left = 0;

barr.postln;
//////////////////////////////////////////////////////
keyarr = Array.fill(15, {arg i;
	Button(w, Rect(630+ left, 525, 114, 625));
	left = left+114;});
left = 57;
key2arr = Array.fill(10, {arg i;
	Button(w, Rect(660+left, 525, 57, 400));
	if (i == 1, {left = left + 114});
	if (i == 4, {left = left + 114});
	if (i == 6, {left = left + 114});
	left = left + 114;
});

left = 0;
knobarr = Array.fill(8, {arg i;
	Knob(w, Rect(1300+left, 50, 80, 80));
	left = left + 120;});
left = 0;
top = 0;

adgBArr = Array.fill(18, {arg i;
	Button(w, Rect (1300+left, 200+top, 100, 50));
	if (i + 1 % 6 == 0, {top = top + 100});
	if (i + 1 % 6 == 0, {left = 0}, {left = left + 150});});

alessis = StaticText.new(w, Rect(700,50,300,200));
alessis.string = "Alessis" ;

/*************************************************************************/
//Done with GUI Stuff - keep note of three arrays: barr, keyarr, key2arr as well as adgBArr, knobarr

// Better yet, use .trace to output all incoming MIDI messages
MIDIFunc.trace(true);

// to turn tracing off:
MIDIFunc.trace( false );

/*while({boolLoop == false},
	{
		v = TextView(w, Rect(0,0,300, 300)) ;
		v.keyDownAction_{|i, char| char.postln} ;
});*/


// the same with MIDIdef's: use the lowest pad to cue events and use knob 0 to change pitch
~padOn = MIDIFunc.noteOn({arg veloc, num, chan, src;
	if (num < 52,
		{playArr[num-36+~padOffset] = bindArr[num-36+~padOffset].play;
			~padOffset.postln;
			if (veloc < 40,
				{AppClock.sched(0, {barr[num-36].valueAction = 1})},
				{if (veloc < 80,
					{AppClock.sched(0, {barr[num-36].valueAction = 2})},
					{AppClock.sched(0, {barr[num-36].valueAction = 3})})})})});
~padOff = MIDIFunc.noteOff({arg veloc, num, chan, src;
	if (num < 52,
		{playArr[num-36+~padOffset].stop})});

////////////////////////////////////////////////////////////////////////////////////////////////////////
~selector = ~instrumentArray[0];
MIDIdef.cc(\ch0, {~selector = ~instrumentArray[0]}, 48, 0);
MIDIdef.cc(\ch1, {~selector = ~instrumentArray[1]}, 49, 0);
MIDIdef.cc(\ch2, {~selector = ~instrumentArray[2]}, 50, 0);
MIDIdef.cc(\ch3, {~selector = ~instrumentArray[3]}, 51, 0);
MIDIdef.cc(\ch4, {~selector = ~instrumentArray[4]}, 52, 0);
MIDIdef.cc(\ch5, {~selector = ~instrumentArray[5]}, 53, 0);
MIDIdef.cc(\ch6, {~selector = ~instrumentArray[6]}, 54, 0);
MIDIdef.cc(\ch7, {~selector = ~instrumentArray[7]}, 55, 0);

MIDIdef.cc(\poff1, {~padOffset = ~padOffset + 16}, 64, 0);
MIDIdef.cc(\poff2, {~padOffset = ~padOffset + 16}, 65, 0);
MIDIdef.cc(\poff3, {~padOffset = ~padOffset - 16}, 66, 0);
MIDIdef.cc(\poff4, {~padOffset = ~padOffset - 16}, 67, 0);


//change octaves
MIDIdef.cc(\octaveUp, {~offset=~offset + 12}, 117, 0);
MIDIdef.cc(\octaveDown, {~offset = ~offset - 12}, 116, 0);



////////////////////////////////////////////////////////////////////////////////////////////////////////
~on = MIDIFunc.noteOn({ |veloc, num, chan, src|
	if (num > 51,
		{keyNums[num-48] = Synth(~selector, [\freq, (num+~offset).midicps])});
	MIDIdef.cc( \roll , { arg val; keyNums[num-48].set( \freq, (num+~offset+val).midicps ) }, 1, 0 );
	MIDIdef.cc( \knob1 , { arg val; keyNums[num-48].set( \amp, val/127 ) }, 20, 0 );
});

~off = MIDIFunc.noteOff({ |veloc, num, chan, src|
	if (num > 51,
		{keyNums[num-48].release})
});


w.front;
)