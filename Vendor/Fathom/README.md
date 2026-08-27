# Vendored [Fathom](https://github.com/jdart1/Fathom) (MIT)

Syzygy tablebase probing by Ronald de Man, with API wrapping by basil00 / Jon Dart.

Only `tbprobe.c` is compiled; it `#include`s `tbchess.c`. Chessblazer calls the
thin wrappers in `chessblazer_fathom.c` / `chessblazer_fathom.h`.

Set UCI `SyzygyPath` to a directory (or `;`-separated list) of `.rtbw` / `.rtbz` files.
