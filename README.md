# DevSound
DevSound is a sound driver for the Game Boy which supports pulse width manipulation, arpeggios, and multiple waveforms. DevSound was designed with homebrew games in mind, so you can easily include it in your project.

# Building the demo ROM on Windows
1. Grab the RGBASM binaries from https://github.com/rednex/rgbds. If you already have them, you can skip this step.
2. Run build.bat. If that doesn't work, try either adding the RGBASM binaries to your PATH or copying them to the repository directory.

# Adding DevSound to your project
1. Copy DevSound.asm, DevSound_Variables.asm, DevSound_Constants.asm, DevSound_Macros.asm, and DevSound_SongData.asm to your project directory.
2. Allocate a ROM bank for DevSound. Make note of the bank number (unless your ROM does not use banking).
3. Add the following line to your main loop: `call DS_Play`
4. In order to load a song, use the following code:
```
ld a,SongID  ; replace SongID with the ID of the song you want to load
call  DS_Init
```
5. In order to stop playback, use the following line of code: `call DS_Stop`
6. In order to fade sound in/out, use the following code:
```
ld  a,X ; replace X with 0 to fade out, replace X with 1 to fade in
call DS_Fade
```
7. If you need help, let me know. I can usually be reached on IRC at irc.efnet.org #gbdev, with the nick DevEd. I may also be reached on Discord in this server: https://discord.gg/gpBxq85. Just ping me (I go by the name DevEd on that server) if you need anything.

# Projects that use DevSound

- **BotB Invitro** (https://github.com/DevEd2/BotBInvite) - A one-screen Game Boy invite I created along with Pigu for Battle of the Bits. *Note: Uses an earlier version of DevSound*

- **Aevilia** (https://github.com/ISSOtm/Aevilia-GB) - An RPG for Game Boy Color by ISSOtm. I'm providing music for the game along with ViLXDRYAD from Battle of the Bits (http://battleofthebits.org). *Note: Uses a modified version of DevSound*

If you are using DevSound in your project, let me know and I'll add it to this list.

# Frequently Asked Questions
*TODO*
