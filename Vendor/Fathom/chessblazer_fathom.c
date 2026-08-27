/*
 * Thin non-inline wrappers so Swift can call Fathom reliably.
 * Fathom itself: Ronald de Man / basil00 / Jon Dart (MIT).
 */
#include "tbprobe.h"
#include "chessblazer_fathom.h"

unsigned chessblazer_tb_largest(void) {
    return TB_LARGEST;
}

bool chessblazer_tb_init(const char *path) {
    return tb_init(path);
}

void chessblazer_tb_free(void) {
    tb_free();
}

unsigned chessblazer_tb_probe_wdl(
    uint64_t white,
    uint64_t black,
    uint64_t kings,
    uint64_t queens,
    uint64_t rooks,
    uint64_t bishops,
    uint64_t knights,
    uint64_t pawns,
    unsigned rule50,
    unsigned castling,
    unsigned ep,
    bool turn
) {
    return tb_probe_wdl(
        white, black, kings, queens, rooks, bishops, knights, pawns,
        rule50, castling, ep, turn
    );
}

unsigned chessblazer_tb_probe_root(
    uint64_t white,
    uint64_t black,
    uint64_t kings,
    uint64_t queens,
    uint64_t rooks,
    uint64_t bishops,
    uint64_t knights,
    uint64_t pawns,
    unsigned rule50,
    unsigned castling,
    unsigned ep,
    bool turn,
    unsigned *results
) {
    return tb_probe_root(
        white, black, kings, queens, rooks, bishops, knights, pawns,
        rule50, castling, ep, turn, results
    );
}
