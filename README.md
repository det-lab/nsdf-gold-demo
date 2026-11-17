# nsdf-gold-demo

A short, hands-on demo of how data from the **NSDF dark matter archive** flows through the `gold*` tools of the
[villano-lab](https://github.com/villano-lab): from the archive, to a processing laid out in the browser, to a fast reduction, to
the raw pulses behind a single peak.

```
nsdf-cli  ->  goldmap  ->  goldsluice  ->  goldpan (notebook)
download      lay out      reduce          look at the quantities,
the dumps     the          every pulse     then at the raw traces
              processing
```

- [`nsdf-cli`](https://nsdf-fabric.github.io/nsdf-slac/) fetches the raw dumps of a series from the archive.
- [goldmap](https://github.com/villano-lab/goldmap) is a local browser app that writes the **dataset definition** (a small text file) that says what to compute.
- [goldsluice](https://github.com/villano-lab/goldsluice) reads the dumps and computes the quantities for every pulse (about 8 seconds for 39,000 events).
- [goldpan](https://github.com/villano-lab/goldpan) reads the result back, and reads the raw traces, in a notebook.

The example is one Run 76 series (`07221115_0845`, -81.7 V), and the notebook goes from a smeared peak in a spectrum, to why it is smeared,
to the pulses themselves.

**Credits.** The analysis approach is due to Anthony Villano. `goldpan`, `goldsluice` and `goldmap` are from the villano-lab. The data and
`nsdf-cli` are from the NSDF / Nexus-DM project. **This repository was written with the help of an AI assistant (Claude Code)**; the
definition was written by `goldmap` itself.

## Try it

You need Python 3.12 and about 1.1 GB of disk for the data. Tested on macOS (Apple silicon); other systems have not been
tried, Windows in particular (activate the environment with `.venv\Scripts\activate` there).

**1. Get the code and install**

```
git clone https://github.com/det-lab/nsdf-gold-demo.git
cd nsdf-gold-demo
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

**2. Fetch the data with `nsdf-cli`** (12 dumps, 1.1 GB; it took under a minute here)

```
nsdf-cli download --file-list dumps-full.txt --output-dir data
```

To only test that the pipeline runs, `dumps-quick.txt` fetches 4 dumps instead. That is about a third of the events, and the peak in the notebook is then barely
above the noise.

**3. Look at the definition in goldmap** (optional; it opens a page in your browser)

```
python -m goldmap --registry registry --root data --folder .
```

In the page: **Data** tab, *Start from an existing definition*, `am-lines.dataset.toml`. Then look at the **Steps** tab, and press **Validate** on the
**Files** tab. Stop it with Ctrl+C.

**4. Reduce the data with goldsluice**

```
python -m goldsluice check am-lines.dataset.toml
python -m goldsluice run am-lines.dataset.toml
```

The result is written to `output/am-lines/` (not tracked by git).

**5. Open the notebook**

```
jupyter lab am-lines-demo.ipynb
```

`am-lines-demo.ipynb` is saved with its output, from the 12 dumps, so you can read it on GitHub first. Run it again on your own data with
*Restart Kernel and Run All Cells*.

## What is here

| | |
|---|---|
| `am-lines.dataset.toml` | the dataset definition (made with goldmap): which dumps, which detector, which steps |
| `series.csv` | the run metadata of the series that the definition refers to |
| `registry/` | the detector registry the definition names (a copy, see `registry/SOURCE.md`) |
| `am-lines-demo.ipynb` | the notebook |
| `dumps-full.txt`, `dumps-quick.txt` | the dumps to fetch (all 12, or 4 for a quick test) |
| `requirements.txt` | the exact versions this was tried with |

## Things to know

- **Nothing is calibrated.** The units are the ones the pulses come in. The notebook sets a *relative* scale from the strong peak alone, through zero, and
  assumes that peak is the 59.5 keV line of Am-241; the lower lines are placed by that scale, not measured.
- **The detector description is inferred.** The channel map of the Side-2 readout (`registry/run76.toml`) is marked `inferred`, and the readout
  (sample period, baseline window) is assumed to be that of another series of the same run. Check them before you trust a number.
- **The position cut is a guide, not a reconstruction.** The "patch" in the notebook is a circle in the plane of the delays between the channels'
  20 % crossing times, with empirical offsets.
- **Trigger labels.** The notebook treats the label `Unknown` as a real trigger, which is the working assumption of `goldpan.cuts` and has not been
  confirmed against the DAQ.

## Data and citation

The NSDF dark matter data has **no licence assigned yet**. Its guidelines ask that you cite:

> Amy Roberts, Jack Marquez, Kin Hong NG, Kitty Mickelson, Aashish Panta, Giorgio Scorzelli, Amy Gooch, Prisca Cushman, Matthew Fritts,
> Himangshu Neog, Valerio Pascucci, Michela Taufer. *The Making of a Community Dark Matter Dataset with the National Science Data Fabric.*
> arXiv:2507.13297 (2025).

See the [Nexus-DM README](https://github.com/nsdf-fabric/nexus-dm#citing-nexus-dm) for the current wording. Raw data and processed output are
not stored in this repository.

## License

The code and text of this repository are MIT licensed (`LICENSE`). The files in `registry/` are copies and keep the license of their source
(`registry/LICENSE-NSDF-Data`).
