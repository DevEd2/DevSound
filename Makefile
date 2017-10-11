PY := python3

all: DevSound.gb DevSound.gbs

%.asm: ;
%.inc: ;
%.bin: ;
DevSound.gb: %.asm %.inc %.bin
	rgbasm -o DevSound.obj -p 255 Main.asm
	rgblink -p 255 -o DevSound.gb -n DevSound.sym DevSound.obj
	rgbfix -v -p 255 DevSound.gb

DevSound.gbs: DevSound.gb
	$(PY) makegbs.py