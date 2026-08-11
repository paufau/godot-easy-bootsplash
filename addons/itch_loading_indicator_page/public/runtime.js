(function () {
	"use strict";

	if (window.ILIP && window.ILIP.installed) {
		return;
	}

	var FADE_MS = 400;
	// How long a shell that loads the engine late gets before the overlay gives up
	// and uncovers what is underneath.
	var GRACE_MS = 3000;
	var ROOT_ID = "ilip";
	var DONE_CLASS = "is-done";

	var progressHandlers = [];
	var doneHandlers = [];
	var root = null;
	var finished = false;
	var dismissed = false;
	var sawEngine = false;
	var ratio = 0;
	var current = 0;
	var total = 0;

	function findRoot() {
		if (root === null) {
			root = document.getElementById(ROOT_ID);
		}

		return root;
	}

	function call(handler, args) {
		try {
			handler.apply(null, args);
		} catch (error) {
			console.error("ILIP: handler failed.", error);
		}
	}

	function setProgress(loaded, size) {
		current = loaded;
		total = size;

		if (size > 0) {
			ratio = Math.max(0, Math.min(1, loaded / size));
		}

		var node = findRoot();

		if (node) {
			node.style.setProperty("--ilip-progress", String(ratio));
			node.style.setProperty("--ilip-progress-percent", (ratio * 100).toFixed(2) + "%");
		}

		for (var i = 0; i < progressHandlers.length; i++) {
			call(progressHandlers[i], [ratio, current, total]);
		}
	}

	function dismiss() {
		if (dismissed) {
			return;
		}

		dismissed = true;

		var node = findRoot();

		if (!node) {
			return;
		}

		node.classList.add(DONE_CLASS);
		window.setTimeout(function () {
			node.remove();
			window.removeEventListener("resize", updateArtBottom);
			root = null;
			progressHandlers.length = 0;
			doneHandlers.length = 0;
		}, FADE_MS);
	}

	function finish(failed) {
		if (finished) {
			if (failed) {
				dismiss();
			}

			return;
		}

		finished = true;
		setProgress(1, 1);

		for (var i = 0; i < doneHandlers.length; i++) {
			call(doneHandlers[i], []);
		}

		if (failed || api.mode === "on-engine-load") {
			dismiss();
		}
	}

	var api = {
		installed: true,
		params: {},
		mode: "on-engine-load",
		onProgress: function (handler) {
			progressHandlers.push(handler);
			call(handler, [ratio, current, total]);

			return api;
		},
		onDone: function (handler) {
			if (finished) {
				call(handler, []);
			} else {
				doneHandlers.push(handler);
			}

			return api;
		},
		hide: dismiss,
		hydrate: hydrateArt,
		getProgress: function () {
			return ratio;
		},
		isDone: function () {
			return finished;
		}
	};

	window.ILIP = api;

	function wrapEngine(engineClass) {
		if (!engineClass || engineClass.ilipWrapped || !engineClass.prototype) {
			return;
		}

		engineClass.ilipWrapped = true;

		["startGame", "start"].forEach(function (name) {
			var original = engineClass.prototype[name];

			if (typeof original !== "function") {
				return;
			}

			sawEngine = true;

			engineClass.prototype[name] = function (override) {
				var config = override || {};
				var inner = config["onProgress"];

				config["onProgress"] = function (loaded, size) {
					setProgress(loaded, size);

					if (typeof inner === "function") {
						inner(loaded, size);
					}
				};

				var result = original.call(this, config);

				if (result && typeof result.then === "function") {
					result.then(function () {
						finish(false);
					}, function () {
						finish(true);
					});
				} else {
					finish(false);
				}

				return result;
			};
		});
	}

	if (typeof window.Engine === "function") {
		wrapEngine(window.Engine);
	} else {
		try {
			var captured;

			Object.defineProperty(window, "Engine", {
				configurable: true,
				enumerable: true,
				get: function () {
					return captured;
				},
				set: function (value) {
					captured = value;
					wrapEngine(value);
				}
			});
		} catch (error) {
			console.warn("ILIP: could not hook Engine, falling back to the shell status.", error);
		}
	}

	// Rendered bottom edge of the artwork, consumed by the template's
	// "below" placement for cover/contain.
	function updateArtBottom() {
		var node = findRoot();

		if (!node) {
			return;
		}

		var bottom;

		if (node.classList.contains("fit-cover")) {
			bottom = node.clientHeight;
		} else if (node.classList.contains("fit-contain")) {
			var art = node.querySelector("img");

			if (!art || !art.naturalWidth || !art.naturalHeight) {
				return;
			}

			var scale = Math.min(node.clientWidth / art.naturalWidth, node.clientHeight / art.naturalHeight);
			bottom = (node.clientHeight + art.naturalHeight * scale) / 2;
		} else {
			return;
		}

		node.style.setProperty("--ilip-art-bottom", bottom.toFixed(1) + "px");
	}

	function hydrateArt() {
		var node = findRoot();
		var art = node && node.querySelector("[data-src]");

		if (!art) {
			return;
		}

		var src = art.getAttribute("data-src");
		art.removeAttribute("data-src");

		if (!src) {
			art.remove();
			return;
		}

		art.addEventListener("load", updateArtBottom);
		art.setAttribute("src", src);
		window.addEventListener("resize", updateArtBottom);
		updateArtBottom();
	}

	function observeShell() {
		hydrateArt();

		var progress = document.getElementById("status-progress");

		if (progress && !sawEngine) {
			var sync = function () {
				var max = Number(progress.max) || 0;
				var value = Number(progress.value) || 0;

				if (max > 0) {
					setProgress(value, max);
				}
			};

			new MutationObserver(sync).observe(progress, {
				attributes: true,
				attributeFilter: ["value", "max"]
			});
			sync();
		}

		var notice = document.getElementById("status-notice");

		if (notice) {
			var checkNotice = function () {
				if (notice.style.display === "block") {
					finish(true);
				}
			};

			new MutationObserver(checkNotice).observe(notice, {
				attributes: true,
				attributeFilter: ["style"]
			});

			checkNotice();
		}

		var status = document.getElementById("status");

		if (status && status.parentNode) {
			new MutationObserver(function (records, observer) {
				if (!document.getElementById("status")) {
					observer.disconnect();
					finish(false);
				}
			}).observe(status.parentNode, { childList: true });
		} else {
			window.setTimeout(function () {
				if (total === 0) {
					finish(true);
				}
			}, GRACE_MS);
		}
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", observeShell);
	} else {
		observeShell();
	}
})();
