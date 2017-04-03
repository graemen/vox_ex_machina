<b>Vox Ex Machina</b>

Speaker verification voice-print security assessment tool<br>

Features:
- text to speech
- real time speech parameter randomisation
- replay and brute force attacks
- add noise and other signals to the audio samples
- API support for MS Azure Coghnitive Services and VoiceIT


Run:<br>
Open vem.scd in SuperCollider and evaluate (select all and press "cmd+Return")<br>


Install:<br>
Linux only and dependencies are:
- Supercollider (from your distro packages)
- Low latency Linux kernel (from your distro packages)
- Python3 (from your distro packages)
- sox (from your distro packages)
- Festival (from your distro packages)
- Mage https://github.com/numediart/mage
- SCMage https://github.com/snappizz/SCMage a SuperCollider plugin
- Hackbright-Project https://github.com/ritchieleeann/Hackbright-Project

Some changes have been made to SCMage and the files are included here so you can replace the originals. There is also a precompiled SCMage.so compiled on Ubuntu 16.10 x86_64<br>
There are currently some paths in a few files that need to be edited in the code. They are marked with "TODO:"<br>

The Festvox voices are under the directory "data".<br>
Obviously you should have some experience using SuperColider. 

Basic help is available on the Wiki https://github.com/graemen/vox/wiki 
