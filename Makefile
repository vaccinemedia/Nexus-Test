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

$(OUTDIR)/nexus.tap $(OUTDIR)/nexus.sna: $(SRC) $(wildcard src/*.asm) $(wildcard src/*.inc) $(LOADER_INC) src/title_music_relocated.akm
	@mkdir -p $(OUTDIR)
	$(ASM) -I src --outprefix=$(OUTDIR) $(SRC)

# Two-pass AKM relocation: first pass gets the song address, then relocate
src/title_music_relocated.akm: src/title_music.akm src/akm_player.bin tools/relocate_akm.py
	@echo "=== Determining AKM song address ==="
	@SONG_ADDR=$$($(ASM) -I src --outprefix=$(OUTDIR) $(SRC) 2>&1 | grep 'AKM_SONG_ORG' | sed 's/.*0x//'); \
	echo "Song address: $$SONG_ADDR"; \
	python3 tools/relocate_akm.py src/title_music.akm src/title_music_relocated.akm $$SONG_ADDR

clean:
	rm -f $(OUTDIR)/nexus.tap $(OUTDIR)/nexus.sna

run: all
	@chmod +x scripts/run-fusex.sh 2>/dev/null || true
	@./scripts/run-fusex.sh
