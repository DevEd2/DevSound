
PY := python3

ASFLAGS = -p 0xff -i ../
LDFLAGS = -p 0xff
FXFLAGS = -p 0xff -v


all: DevSound.gbc DevSound.gbs
.PHONY: all

clean:
	-rm DevSound.gbc
	-rm DevSound_GBS.gbc DevSound.gbs
	-rm *.o *.obj
.PHONY: clean

%.obj: %.asm
	rgbasm $(ASFLAGS) -o $@ $<
%_GBS.obj: %.asm
	rgbasm $(ASFLAGS) -DGBS -o $@ $<

DevSound.gbc: Main.obj
	rgblink $(LDFLAGS) -o $@ -n $(@:.gbc=.sym) $^
	rgbfix $(FXFLAGS) $@
DevSound_GBS.gbc: Main_GBS.obj
	rgblink $(LDFLAGS) -o $@ $^

DevSound.gbs: DevSound_GBS.gbc
	$(PY) makegbs.py
