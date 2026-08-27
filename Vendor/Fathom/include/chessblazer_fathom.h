#ifndef CHESSBLAZER_FATHOM_H
#define CHESSBLAZER_FATHOM_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

unsigned chessblazer_tb_largest(void);
bool chessblazer_tb_init(const char *path);
void chessblazer_tb_free(void);

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
);

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
);

#ifdef __cplusplus
}
#endif

#endif
