<b>Vox Ex Machina</b>

Speaker verification voice-print security assessment tool<br>

Features in vem.scd:
- arbitary text to speech
- real time speech parameter randomisation
- enrollment and authorisation
- replay and brute force attacks
- add noise to the audio samples 
- API support for MS Azure Cognitive Services 
- API suport for VoiceIT

Additional features in development vemfuzzer.scd: 
- generate DTMF for fuzzing of interactive phone systems
- generate SS5 tones for fuzzing of really old school phone networks
- generate BlueVox tones for fuzzing of one time auio password systems
- loading of a script for auto generation of audio
- microphone access for capturing speech recognition system responses while fuzzing

Run:<br>
Open vem.scd / vemfuzz.scd in SuperCollider and evaluate (select all and press "cmd+Return")<br>

Install:<br>
MacOS and Linux with these dependencies:
- Supercollider (from your distro packages)
- Low latency Linux kernel (from your distro packages, Linux only)
- Python3 (from your distro packages or brew )
- sox (from your distro packages or brew )
- Mage https://github.com/numediart/mage 
- SCMage https://github.com/snappizz/SCMage a SuperCollider plugin includes scripts for downloading, compiing and installing Festival and SpeechTools
- [Optional] Hackbright-Project https://github.com/ritchieleeann/Hackbright-Project for local API testing

Some changes have been made to SCMage and the files are included here so you can replace the originals. 
There is also a precompiled SCMage.so compiled on Ubuntu 16.10 x86_64<br>
There are currently some paths in a few files that need to be edited in the code. They are marked with "TODO:"<br>

To get it all working build Festival and the SpeechTools using the scripts provided in SCMage. 
Edit the file paths in SCMage.sc and copy the relevant binaries from examples to bin dirs. 
Copy SCMage.sc to ~/.local/share/SuperCollider/Extensions/classes. 
Copy SCMage.so to ~/.local/share/SuperCollider/Extensions/plugins.
Make sure the data dir including here lives under the mage dir and supply a shortcut to it in the voix directory.

The Festvox voices are under the directory "data".<br>
Obviously you should have some experience using SuperCollider. 

Basic help is available on the Wiki https://github.com/graemen/vox/wiki 

A hardware implementation of this on Bela is in development. This will be all open source.

