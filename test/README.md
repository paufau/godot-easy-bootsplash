## Run

```sh
python3 test/serve.py
```

## Use

<http://localhost:8000/test/>

## Case flags

`case.html` accepts any template parameter plus a few controls in the query string:

- `dismiss=1` — the fake engine finishes at 100% instead of looping forever
- `jump=1` — ramp to 20%, stall for a beat, then report 100% in one step
- `hideAt=20` — call `window.ILIP.hide()` once loading passes 20%
- `restart=0` — do not reload the page after the overlay is removed (by
  default a finished case pauses on the lamps for a moment and starts over)

The lamps in the top-left corner light up when `hide()` is called and when the
overlay is actually removed, each showing the displayed progress at that moment —
so the gap between "hide requested" and "overlay gone" is visible with
`progress_smoothing_ms` / `hide_awaits_full_progress`.
