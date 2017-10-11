# makegbs.py - create GBS file from DevSound.gb

# open files
ROMFile = open("DevSound.gb", "rb")     # demo ROM
OutFile = open("DevSound.gbs", "wb")    # output file

# find end of data
endpos = ROMFile.seek(-1,2) + 1
while endpos >= 0x4000:
    if ROMFile.read(1)[0] != 0xff: break;
    ROMFile.seek(-2,1)
    endpos -= 1

# copy song data
ROMFile.seek(0x3f90)
OutFile.write(ROMFile.read(endpos - 0x3f90))       # write song data

# close files
ROMFile.close()
OutFile.close()
