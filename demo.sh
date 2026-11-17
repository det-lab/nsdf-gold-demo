#!/usr/bin/env bash
# The demo, paced: each step prints what it is about to do and waits for Enter.
#
#   ./demo.sh           # step by step (press Enter to run each step)
#   ./demo.sh --auto    # no pauses (to test that everything works)
#
# Run it from anywhere; it works in this folder. It uses ./.venv if you made one (see README) or else the
# environment that is already active. Set DEMO_NOOPEN=1 to keep it from opening browser tabs, and
# DUMPS=dumps-quick.txt to fetch 4 dumps instead of all 12 (a quick test: the peak is then barely visible).
set -u
cd "$(dirname "$0")" || exit 1

AUTO=0; [ "${1:-}" = "--auto" ] && AUTO=1
DUMPS="${DUMPS:-dumps-full.txt}"
DEFN=am-lines.dataset.toml
NOTEBOOK=am-lines-demo.ipynb
PIDS=()

if [ -z "${VIRTUAL_ENV:-}" ] && [ -f .venv/bin/activate ]; then
    # shellcheck disable=SC1091
    . .venv/bin/activate
fi
command -v nsdf-cli >/dev/null 2>&1 || { echo "nsdf-cli not found: make and activate the environment first (README, step 1)." >&2; exit 1; }

bold()   { printf '\033[1;36m%s\033[0m\n' "$*"; }
cmdline() { printf '\033[33m   $ %s\033[0m\n' "$*"; }

pause_for() { [ "$AUTO" = 1 ] && return; read -r -p "   [Enter to run] " _ < /dev/tty; }

# step "what we are doing" "command shown and run"
step() {
    echo; bold "== $1"; cmdline "$2"; pause_for
    eval "$2"; local code=$?
    [ $code -ne 0 ] && printf '\033[31m   (exit status %s)\033[0m\n' "$code"
    return $code
}

open_url() {
    [ -n "${DEMO_NOOPEN:-}" ] && return
    if command -v open >/dev/null 2>&1; then open "$1"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1; fi
}

cleanup() {
    for pid in "${PIDS[@]:-}"; do
        [ -n "$pid" ] && { pkill -P "$pid" 2>/dev/null; kill "$pid" 2>/dev/null; }
    done
}
trap cleanup EXIT

# wait_for_url LOGFILE REGEX  ->  prints the first match, waiting up to 20 s
wait_for_url() {
    local i url
    for i in $(seq 1 40); do
        url=$(grep -Eo "$2" "$1" 2>/dev/null | head -1)
        [ -n "$url" ] && { echo "$url"; return 0; }
        sleep 0.5
    done
    return 1
}

bold "NSDF data -> goldmap -> goldsluice -> goldpan"
echo "environment: $(python --version 2>&1), goldpan $(python -c 'import goldpan; print(goldpan.__version__)' 2>/dev/null)"

# 1. the data
if [ "$(ls data 2>/dev/null | grep -c '^07221115_0845_F')" -ge "$(grep -c . "$DUMPS")" ]; then
    echo; bold "== The dumps are already here (fetched with: nsdf-cli download --file-list $DUMPS --output-dir data)"
    cmdline "ls data; du -sh data"; pause_for; ls data; du -sh data
else
    step "Fetch the raw dumps from the NSDF archive" "nsdf-cli download --file-list $DUMPS --output-dir data"
fi

# 2. goldmap
echo; bold "== Start goldmap (it runs in the background; a browser tab opens)"
cmdline "python -m goldmap --registry registry --root data --folder ."
pause_for
GMLOG=$(mktemp)
python -u -m goldmap --registry registry --root data --folder . > "$GMLOG" 2>&1 &
PIDS+=($!)
if GMURL=$(wait_for_url "$GMLOG" 'http://127\.0\.0\.1:[0-9]+/'); then
    echo "   goldmap is at $GMURL"; open_url "$GMURL"
else
    echo "   goldmap did not start; log:"; cat "$GMLOG"
fi
echo "   In the page: Data tab -> 'Start from an existing definition' -> $DEFN"
echo "   Then: Steps tab (subtract_line, window_integral, baseline, rise_crossing), Files tab -> Validate (do not press Write)."

# 3. goldsluice, live
step "Start clean (remove an earlier output so the run really computes)" "rm -rf output/am-lines"
step "Check the definition: lists the raw files, runs nothing" "python -m goldsluice check $DEFN"
step "Run goldsluice" "python -m goldsluice run $DEFN"
step "What it wrote" "ls output/am-lines output/am-lines/NAI-S2"

# 4. goldpan notebook
echo; bold "== Start JupyterLab (background; a browser tab opens)"
cmdline "jupyter lab $NOTEBOOK"
pause_for
JLOG=$(mktemp)
python -m jupyter lab --no-browser "$NOTEBOOK" > "$JLOG" 2>&1 &
PIDS+=($!)
if JURL=$(wait_for_url "$JLOG" 'http://(127\.0\.0\.1|localhost):[0-9]+/[^ ]*token=[0-9a-f]+'); then
    NBURL=$(echo "$JURL" | sed "s#/lab?#/lab/tree/$NOTEBOOK?#")
    echo "   notebook: $NBURL"; open_url "$NBURL"
else
    echo "   JupyterLab did not start; log:"; cat "$JLOG"
fi
echo "   Restart Kernel and Run All Cells re-makes every figure from the data you just reduced (about 10 s)."
echo "   Notebook: 1 the smeared peak and the Am lines, 2 the peak against the baseline, 3 the raw pulses with their baseline estimate."

# 5. finish
if [ "$AUTO" = 1 ]; then
    echo; echo "(auto mode: checking both servers answer, then stopping them)"
    [ -n "${GMURL:-}" ] && curl -s -o /dev/null -w "goldmap HTTP %{http_code}\n" "$GMURL"
    [ -n "${JURL:-}" ]  && curl -s -o /dev/null -w "jupyter HTTP %{http_code}\n" "$JURL"
else
    read -r -p "[Enter to stop goldmap and JupyterLab] " _ < /dev/tty
fi
