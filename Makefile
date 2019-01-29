PY := python3

all: DevSound.gbc DevSound.gbs

%.o: %.asm
	rgbasm -o $@ -p 0xff $<
%_GBS.o: %.asm
	rgbasm -DGBS -o $@ -p 0xff $<

DevSound.gbc: Main.o
	rgblink -p 0xff -o $@ -n $(@:.gbc=.sym) $^
	rgbfix -v -p 0xff $@
DevSound_GBS.gbc: Main_GBS.o
	rgblink -p 255 -o $@ $^

DevSound.gbs: DevSound_GBS.gbc
	$(PY) makegbs.py
	rm $<
