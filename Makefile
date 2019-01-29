PY := python3

all: DevSound.gbc DevSound.gbs

%.obj: %.asm
	rgbasm -o $@ -p 0xff $<
%_GBS.obj: %.asm
	rgbasm -DGBS -o $@ -p 0xff $<

DevSound.gbc: Main.obj
	rgblink -p 0xff -o $@ -n $(@:.gbc=.sym) $^
	rgbfix -v -p 0xff $@
DevSound_GBS.gbc: Main_GBS.obj
	rgblink -p 255 -o $@ $^

DevSound.gbs: DevSound_GBS.gbc
	$(PY) makegbs.py
	rm $<
