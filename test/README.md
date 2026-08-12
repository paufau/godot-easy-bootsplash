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
- `hideAt=20` — call `window.EBS.hide()` once loading passes 20%
- `restart=0` — do not reload the page after the overlay is removed (by
  default a finished case pauses on the lamps for a moment and starts over)
- `template=special/15th-mile.html` — render a template other than
  `default_template.html`, the same way the `ebs/template` export option does.
  The path is relative to `case.html`.
- `image=…/art.svg` — what `{{IMAGE_SRC}}` resolves to, relative to `case.html`

## Custom templates

`special/15th-mile.html` is a template with no bar at all: it inlines the
artwork and drives the two accent strokes off `--ebs-progress` instead.

Each stroke is a single dash whose *length* is the progress, pinned at the point
where its path crosses into the frame and growing backwards from there. Blue is
pinned to the left edge and grows down; orange is pinned to the right edge and
grows up. Two custom properties per line carry the measurements:

- `--ebs-line-from` — distance along the path of the pinned end
- `--ebs-line-span` — how much of the path is on screen, i.e. the full 100%
- `--ebs-line-length` — at least the path length, used as the trailing gap so
  the dash pattern never repeats

Both paths run far outside the artwork's 1920&times;1080 frame at either end, so
`from` / `span` deliberately cover only the visible stretch — mapping 0&ndash;100%
onto the whole path would spend a third of the load drawing off-canvas. The
bench asserts the dash length tracks progress, that the pinned end never drifts,
and that the growing end stays inside the frame across the whole 0&ndash;100% sweep.

The inlined artwork departs from the exported Figma source in three places,
all because it was drawn as a still: the progress bar baked into it is gone, the
white blurred wash sits *behind* the two strokes rather than over them, and the
stroke gradients fade past the frame edge instead of towards it. In the original
order the advancing tip washed out as it moved, which reads as the line
retreating rather than growing.

To inspect a single progress value, open the case with `restart=0` and set
`--ebs-progress` on `#ebs` by hand. Drive it from the console rather than from a
page of its own: without an engine reporting progress, `runtime.js` hits its
`GRACE_MS` window, decides the shell is broken and pulls the overlay off the
page after three seconds.

The lamps in the top-left corner light up when `hide()` is called and when the
overlay is actually removed, each showing the displayed progress at that moment —
so the gap between "hide requested" and "overlay gone" is visible with
`progress_smoothing_ms` / `hide_awaits_full_progress`.
