# Easy Bootsplash

![Static Badge](https://img.shields.io/badge/engine-Godot_4.x-478CBF)
![Static Badge](https://img.shields.io/badge/platform-Web-7a34eb)
![Static Badge](https://img.shields.io/badge/shell-untouched-81B622)

A loading screen for Godot web exports that covers the `index.wasm` and `index.pck` download. Built with itch.io in mind, works on any web host.

## ✨ Features

- 🚀 Quick and easy setup with a bunch of pre-made options
- 🖼️ Shows your art while the game downloads
- 🎨 Built-in look configuration available from the export preset
- 🧩 Replace default template with HTML of your own

## Usage

1. Install the addon from Asset Store or from source (copy addons folder to your project directory)
1. Enable the plugin in your Project Settings
1. Replace `addons/easy_bootsplash/assets/background` with your game icon or image
1. Go to Project -> Export -> Web -> "Easy Bootsplash" section
1. Configure properties to customize the look
1. Export the project

## Use cases

**Fullscreen key art, no bar.** Set `Parameters` to `{ "fit": "cover", "progress_hidden": true }`.

**Art plus a thin bar pinned to the bottom.** `{ "fit": "cover", "progress_placement": "bottom", "progress_width": "100vw", "progress_height": "12px", "progress_color": "#7CFF6D" }`.

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
| `progress_placement` | `below` to sit under the artwork (falls back to the page bottom when there is no room, e.g. with `cover`), or `top` / `center` / `bottom` to pin it to an edge |
| `progress_width`     | `min(50vw, 360px)`                                           |
| `progress_height`    | `10px`                                                       |
| `progress_radius`    | `999px`; set `0` for square corners                          |
| `progress_margin`    | `12px` gap between the bar and the page edge for `top` / `bottom` (and the `below` fallback); set `0` to touch the edge |
| `progress_color`     | `#FF244A`                                                    |
| `track_color`        | `rgba(255, 255, 255, 0.9)`                                   |

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

When the overlay is dismissed the root gets the class `is-done`, then leaves the DOM 400 ms later, which is room for a CSS transition on that class.

## Migrating from 1.x

The addon used to be called _Itch Loading Indicator Page_, and 2.0.0 renames everything it exposes. Nothing is aliased, so a 1.x project needs four steps:

1. Delete the old `addons/itch_loading_indicator_page` directory.
1. Disable and re-enable the plugin in Project Settings. That swaps the `ILIPAutoHide` autoload for `EBSAutoHide`.
1. Re-set the options in Project -> Export -> Web -> "Easy Bootsplash". The old `itch_loading_indicator_page/*` keys in `export_presets.cfg` are no longer read.
1. In game code, replace `ILIP.` with `EBS.`.

In a custom template, rename the ids and custom properties:

| 1.x                             | 2.0.0                         |
| ------------------------------- | ----------------------------- |
| `#ilip`                         | `#ebs`                        |
| `#ilip-art`, `-track`, `-fill`  | `#ebs-art`, `-track`, `-fill` |
| `--ilip-progress`, and the rest | `--ebs-progress`, and the rest |
| `window.ILIP`                   | `window.EBS`                  |

The exported assets directory is now `ebs_assets/` instead of `ilip_assets/`.

## Author

- [Pavel Pakseev](https://www.linkedin.com/in/pavel-pakseev/)

## Sponsor & Support

If you found the addon useful, you can support me here:

<a href='https://ko-fi.com/Y8Y315L7NK' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi2.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
