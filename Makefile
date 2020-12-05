AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame

ASFLAGS=

.PHONY: data clean

all: bublbobl

data: bublbobl.zip
	mkdir -p data
	cp bublbobl.zip data && cd data && unzip -o bublbobl.zip && rm bublbobl.zip

prg.orig: data
	cp data/a78-06-1.51 prg.orig

prg.o: prg.orig
	$(AS) $(SRC) $(ASFLAGS) -o prg.o

prg.bin: prg.o
	$(P2BIN) $< $@ -r \$$-0x07FFF

bublbobl: prg.bin
	mkdir -p bublbobl
	cp data/* bublbobl/
	cp prg.bin bublbobl/a78-06-1.51

test: bublbobl
	$(MAME) -rompath $(shell pwd) -debug bublbobl

clean:
	@-rm -rf bublbobl
	@-rm -f prg.o
	@-rm -f prg.bin
