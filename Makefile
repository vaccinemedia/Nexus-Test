# ZX Spectrum 128 — Nexus (sjasmplus → TAP)
OUTDIR := out
ASM := sjasmplus
RASM := /tmp/rasm/rasm
SRC := src/nexus.asm
LOADER_GEN := tools/gen_loader.py
LOADER_INC := src/loader_basic.inc

.PHONY: all clean run

all: $(OUTDIR)/nexus.tap

$(LOADER_INC): $(LOADER_GEN)
	python3 $(LOADER_GEN) > $(LOADER_INC)

# Final build — depends on relocated song and compiled player
$(OUTDIR)/nexus.tap: $(SRC) $(wildcard src/*.asm) $(wildcard src/*.inc) $(LOADER_INC) src/akm_player.bin src/title_music_relocated.akm
	@mkdir -p $(OUTDIR)
	$(ASM) -I src --outprefix=$(OUTDIR) $(SRC)

# Determine addresses, compile player, relocate song in one step
src/akm_player.bin src/title_music_relocated.akm: src/title_music.akm src/title_music_playerconfig.asm src/PlayerAkm_rasm.asm src/akm_build.asm tools/relocate_akm.py $(SRC) $(wildcard src/*.asm) $(wildcard src/*.inc) $(LOADER_INC)
	@mkdir -p $(OUTDIR)
	@echo "=== Pass 1: determining Arkos player address ==="
	@PLAYER_ORG=$$($(ASM) -I src --outprefix=$(OUTDIR) $(SRC) 2>&1 | grep 'AKM_PLAYER_ORG' | sed 's/.*0x//'); \
	echo "Player ORG: 0x$$PLAYER_ORG"; \
	echo "=== Compiling Arkos AKM player at 0x$$PLAYER_ORG ===" ; \
	cd src && $(RASM) akm_build.asm -ob akm_player.bin -DAKM_ORG=0x$$PLAYER_ORG 2>&1 && cd .. ; \
	PLAYER_SIZE=$$(wc -c < src/akm_player.bin | tr -d ' '); \
	SONG_ORG=$$(python3 -c "print(format(0x$$PLAYER_ORG + $$PLAYER_SIZE, 'X'))"); \
	echo "Song ORG: 0x$$SONG_ORG (player + $$PLAYER_SIZE bytes)"; \
	python3 tools/relocate_akm.py src/title_music.akm src/title_music_relocated.akm $$SONG_ORG

clean:
	rm -f $(OUTDIR)/nexus.tap src/akm_player.bin src/title_music_relocated.akm

run: all
	@chmod +x scripts/run-fusex.sh 2>/dev/null || true
	@./scripts/run-fusex.sh