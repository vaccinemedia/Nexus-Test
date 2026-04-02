# ZX Spectrum 128 — Nexus (sjasmplus → TAP)
OUTDIR := out
ASM := sjasmplus
SRC := src/nexus.asm
LOADER_GEN := tools/gen_loader.py
LOADER_INC := src/loader_basic.inc

.PHONY: all clean run

# Depend on both artefacts; otherwise `make` can skip when only .tap exists and .sna is missing/stale
all: $(OUTDIR)/nexus.tap $(OUTDIR)/nexus.sna

$(LOADER_INC): $(LOADER_GEN)
	python3 $(LOADER_GEN) > $(LOADER_INC)

$(OUTDIR)/nexus.tap $(OUTDIR)/nexus.sna: $(SRC) $(wildcard src/*.asm) $(wildcard src/*.inc) $(LOADER_INC)
	@mkdir -p $(OUTDIR)
	$(ASM) -I src --outprefix=$(OUTDIR) $(SRC)

clean:
	rm -f $(OUTDIR)/nexus.tap $(OUTDIR)/nexus.sna

run: all
	@chmod +x scripts/run-fusex.sh 2>/dev/null || true
	@./scripts/run-fusex.sh
