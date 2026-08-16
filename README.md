# Easy Bootsplash

![Static Badge](https://img.shields.io/badge/engine-Godot_4.x-478CBF)
![Static Badge](https://img.shields.io/badge/platform-Web-7a34eb)
![Static Badge](https://img.shields.io/badge/shell-untouched-81B622)

Custom loading screen for Godot web exports, which replaces the default loading bar on itch.io while your game downloads

<table>
	<tr>
		<td width="50%"><img alt="Centered art with the bar below it" src="https://raw.githubusercontent.com/paufau/godot-easy-bootsplash/refs/heads/main/assets/rec1.gif" /></td>
		<td width="50%"><img alt="Key art covering the screen, thin bar at the bottom" src="https://raw.githubusercontent.com/paufau/godot-easy-bootsplash/refs/heads/main/assets/rec2.gif" /></td>
	</tr>
	<tr>
		<td align="center">Defaults: art centered, bar below</td>
		<td align="center">image <code>fit: cover</code> with progress at the bottom</td>
	</tr>
	<tr>
		<td><img alt="Centered art with a full-width bar pinned to the bottom edge" src="https://raw.githubusercontent.com/paufau/godot-easy-bootsplash/refs/heads/main/assets/rec3.gif" /></td>
		<td><img alt="Custom template with an animated SVG logo" src="https://raw.githubusercontent.com/paufau/godot-easy-bootsplash/refs/heads/main/assets/rec4.gif" /></td>
	</tr>
	<tr>
		<td align="center">Full-width progress at the very bottom</td>
		<td align="center">Any custom HTML template of your own</td>
	</tr>
</table>

See list of other configuration options supported on the [live test bench](https://paufau.github.io/godot-easy-bootsplash/test/).

## ✨ Features

- 🚀 Quick and easy setup with a bunch of pre-made options
- 🖼️ Shows your art while the game downloads
- 🎨 Built-in look configuration available from the export preset
- 🧩 Replace default template with HTML of your own

## Usage

1. Install the addon from [Asset Library](https://godotengine.org/asset-library/asset/5394) or from source (copy addons folder to your project directory)
1. Enable the plugin in your Project Settings
1. Replace `addons/easy_bootsplash/assets/background` with your game icon or image
1. Go to Project -> Export -> Web -> "Easy Bootsplash" section
1. Configure properties to customize the look
1. Export the project

## Use cases

**Fullscreen key art, no bar.** Set `Parameters` to

```json
{
  "fit": "cover",
  "progress_hidden": true
}
```

**Art plus a thin bar pinned to the bottom.**

```json
{
  "fit": "cover",
  "progress_placement": "bottom",
  "progress_width": "100vw",
  "progress_height": "12px",
  "progress_color": "#7CFF6D"
}
```

**Your own markup.** Copy `public/default_template.html`, point `Template` at the copy, and address anything from `Assets` as `{{ASSETS_DIR}}/logo.svg`.

**An intro of your own.** Set `Dismiss` to `Manually` and call `EBS.hide()` from GDScript when your first cutscene is ready to be seen.

---

## Export options

### `Enabled: bool = true`

Turn the overlay off for a single preset.

---

### `Dismiss: "On Engine Load" | "After First Frame Drawn" | "Manually" = "After First Frame Drawn"`

When the overlay goes.

- `After First Frame Drawn` waits for `RenderingServer.frame_post_draw`, so the loader will disappear right after the first game frame is drawn.
- `On Engine Load` uses the engine's own start signal, which fires before the first frame is drawn, so the player might see an unfilled frame.
- `Manually` leaves it to `EBS.hide()` call in your own code.

---

### `Template: String = "addons/easy_bootsplash/public/default_template.html"`

HTML file to render.

---

### `Parameters: Dictionary`

Values substituted into the template, and carried into the game. The editor keeps the type you picked, so a bool is still a bool where it lands.

> _Note_: Only what JSON format can carry survives the trip to the page: _strings, numbers, bools, arrays and dictionaries_. A `Color` or a `Vector2` arrives as its Godot stringified form.

---

### `Assets: String = "addons/easy_bootsplash/assets"`

Directory copied next to the shell as `ebs_assets/`, recursively.
`.import` files and dotfiles are skipped

---

## Parameters the built-in template reads

| Key                  | Default                                                      |
| -------------------- | ------------------------------------------------------------ |
| `background_color`   | `#5F5F5F`                                                    |
| `fit`                | `centered`, or `cover` / `contain` to fill the screen        |
| `progress_hidden`    | `false`; `true` drops the bar                                |
| `progress_placement` | `below`, or `top` / `center` / `bottom` to pin it to an edge |
| `progress_width`     | `min(50vw, 360px)`                                           |
| `progress_height`    | `10px`                                                       |
| `progress_radius`    | `999px`                                                      |
| `progress_margin`    | `12px`; gap between the bar and the screen edge / artwork    |
| `progress_color`     | `#FF244A`                                                    |
| `track_color`        | `rgba(255, 255, 255, 0.9)`                                   |

Two more keys are read by the runtime rather than the template:

| Key                         | Default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `progress_smoothing_ms`     | `600`. Time to close 90% of the distance to the real progress, whatever that distance is. The bar follows instead of jumping, moving fast while it is far behind and easing off as it arrives, and the overlay waits for the animation to finish before fading out. Raise it for calmer motion at the cost of trailing further behind; lower it to track the loader more tightly. `0` disables smoothing, leaving the bar to step with the loader (a CSS transition in the template can smooth that instead). On a load failure the bar snaps and the overlay closes immediately. |
| `hide_awaits_full_progress` | `false`. When `true`, `EBS.hide()` first drives the bar to 100% (animated when smoothing is on) and only then hides the overlay.                                                                                                                                                                                                                                                                                                                                                                                                                                                  |

Feel free to add your own keys if you need to customize your own template

## Writing a template

Tokens are substituted as plain text, and a parameter of the same name overrides a built-in token. The root element needs `id="ebs"`; the runtime finds it by that id.

| Token              | Value                                                               |
| ------------------ | ------------------------------------------------------------------- |
| `{{IMAGE_SRC}}`    | Path of the `background.*` that was found, empty when there is none |
| `{{ASSETS_DIR}}`   | Directory the assets were copied into, empty when unset             |
| `{{PROJECT_NAME}}` | `application/config/name`                                           |
| `{{any_key}}`      | Any key from `Parameters`. Objects and arrays arrive as JSON        |

```html
<div id="ebs">
  <img alt="" data-src="{{IMAGE_SRC}}" />
  <p>{{tagline}}</p>
  <div class="bar"><i></i></div>
</div>
<style>
  #ebs {
    position: absolute;
    inset: 0;
    z-index: 3;
    background: #101014;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    transition: opacity 0.35s ease-out;
  }
  #ebs.is-done {
    opacity: 0;
    pointer-events: none;
  }
  .bar {
    width: 320px;
    height: 8px;
    background: #ffffff2e;
  }
  .bar i {
    display: block;
    height: 100%;
    width: var(--ebs-progress-percent, 0%);
    background: #7cff6d;
    transition: width 0.2s linear;
  }
</style>
```

## Runtime API

Two CSS custom properties on the root element stay up to date:

```css
#my-bar {
  width: var(--ebs-progress-percent, 0%);
} /* "42.00%" */
#my-ring {
  opacity: var(--ebs-progress, 0);
} /* 0..1 */
```

> When the overlay is dismissed the root gets the class `is-done`, then leaves the DOM 400 ms later, which is room for a CSS transition on that class.

## Author

- [Pavel Pakseev](https://www.linkedin.com/in/pavel-pakseev/)

## Sponsor & Support

⭐ _Star_ ⭐ the repo if it saved you time

You can also support me here:

<a href='https://ko-fi.com/Y8Y315L7NK' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi2.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
