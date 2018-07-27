PY := python3

all: DevSound.gbc DevSound.gbs

%.asm: ;
%.inc: ;
%.bin: ;
DevSound.gb: %.asm %.inc %.bin
	rgbasm -o DevSound.obj -p 255 Main.asm
	rgblink -p 255 -o DevSound.gbc -n DevSound.sym DevSound.obj
	rgbfix -v -p 255 DevSound.gbc

DevSound.gbs: %.asm %.inc %.bin
	rgbasm -DGBS -o DevSound_GBS.obj -p 255 Main.asm
	rgblink -p 255 -o DevSound_GBS.gbc DevSound_GBS.obj
	$(PY) makegbs.py
	rm -f DevSound_GBS.obj DevSound_GBS.gbc
