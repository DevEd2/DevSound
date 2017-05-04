# makegbs.py - create GBS file from GBSHeader.bin and DevSound.gb

# open files
HdrFile = open("GBSHeader.bin", "rb") # GBS header
ROMFile = open("DevSound.gb", "rb")   # demo ROM
OutFile = open("DevSound.gbs", "wb")  # output file

# copy header
OutFile.write(HdrFile.read(0x70))     # write GBS header

# copy DevSound + song data
ROMFile.seek(0x40)                    # relevant data starts at offset 0x4000
OutFile.write(ROMFile.read(0x4000))   # write song data

# close files
HdrFile.close()
ROMFile.close()
OutFile.close()
