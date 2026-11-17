# Where these files come from

`run76.toml` and `readouts.toml` are copies of the detector registry of
[villano-lab/NSDF-Data](https://github.com/villano-lab/NSDF-Data) (folder `registry/`), taken from its
`develop` branch at commit `0f911514045ef33f55d05ac60cda4c68e9d496e7`, **unchanged**. They are copied here only so that this demo runs without
cloning that repository. The source of truth is there: if the two differ, trust NSDF-Data.
They are MIT licensed by their authors (`LICENSE-NSDF-Data`, next to this file), not by this repository.

Every record carries a `status` and its `evidence`. The Side-2 channel map of `NAI-S2` is marked **inferred**.
