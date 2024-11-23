# DevSound
DevSound is a sound driver for the Game Boy which supports pulse width manipulation, arpeggios, and multiple waveforms. This version is no longer under development, and I recommend using [DevSound X](https://github.com/DevEd2/DevSoundX) instead.

# Building a demo ROM and/or GBS
Note that the demo ROM is included already; these instructions are if you want to try your own modifications.

## Windows
1. Grab the [RGBASM binaries](https://github.com/rednex/rgbds/releases). If you already have them, you can skip this step.
2. Open a command prompt in the `demo` folder.
3. Run build.bat. If that doesn't work, try either adding the RGBASM binaries to your PATH or copying them to the repository directory.

## Linux
1. Install [RGBDS](https://github.com/rednex/rgbds). If RGBDS is already installed, skip this step.
2. Open a terminal in the `demo` folder.
3. Run `make`.

# Adding DevSound to your project
1. Copy DevSound.asm, DevSound_Variables.asm, DevSound_Constants.asm, DevSound_Macros.asm, DevSound_SongData.asm, and NoiseData.bin to your project directory. If you're not using a file such as [hardware.inc](https://github.com/tobiasvl/hardware.inc) or gbhw.inc, you will need to include it as well.
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

- **Aevilia** (https://github.com/ISSOtm/Aevilia-GB) - An RPG for Game Boy Color by ISSOtm, which I'm providing music for.

- **Scoot the Burbs** (https://github.com/DevEd2/ScootTheBurbs) - A Vinesauce-related project I am currently working on.

If you are using DevSound in your project, let me know and I'll add it to this list.

# Frequently Asked Questions
*TODO*
