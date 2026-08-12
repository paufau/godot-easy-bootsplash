(function () {
	"use strict";

	if (window.EBS && window.EBS.installed) {
		return;
	}

	var FADE_MS = 400;
	// How long a shell that loads the engine late gets before the overlay gives up
	// and uncovers what is underneath.
	var GRACE_MS = 3000;
	var ROOT_ID = "ebs";
	var DONE_CLASS = "is-done";
	var SMOOTH_CLASS = "is-smooth";
	var MAX_TICK_MS = 100;
	var SETTLE_EPSILON = 0.0005;
	var CLOSE_90_TAUS = Math.log(10);

	var progressHandlers = [];
	var doneHandlers = [];
	var root = null;
	var finished = false;
	var dismissed = false;
	var sawEngine = false;
	var ratio = 0;
	var current = 0;
	var total = 0;
	var displayed = 0;
	var animating = false;
	var lastTick = 0;
	var pendingDismiss = false;
	var failedFinish = false;
	var floorRatio = 0;
	var dismissCeiling = 0;

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
			console.error("EBS: handler failed.", error);
		}
	}

	function smoothingMs() {
		var value = Number(api.params && api.params.progress_smoothing_ms);

		return isFinite(value) && value > 0 ? value : 0;
	}

	function awaitsFull() {
		return !!(api.params && api.params.hide_awaits_full_progress === true);
	}

	function render(value) {
		var node = findRoot();

		if (node) {
			node.style.setProperty("--ebs-progress", String(value));
			node.style.setProperty("--ebs-progress-percent", (value * 100).toFixed(2) + "%");
		}
	}

	function targetRatio() {
		var value = Math.max(ratio, floorRatio);

		return pendingDismiss ? Math.min(value, dismissCeiling) : value;
	}

	function tick(now) {
		if (dismissed) {
			animating = false;
			return;
		}

		var target = targetRatio();
		var ms = smoothingMs();
		var dt = Math.min(Math.max(now - lastTick, 0), MAX_TICK_MS);

		lastTick = now;

		if (target <= displayed || !(ms > 0)) {
			displayed = target;
		} else {
			var gap = target - displayed;
			var step = gap * (1 - Math.exp(-dt * CLOSE_90_TAUS / ms));

			if (pendingDismiss) {
				step = Math.max(step, dt / ms);
			}

			displayed = gap - step < SETTLE_EPSILON ? target : displayed + step;
		}

		render(displayed);

		if (displayed < target) {
			window.requestAnimationFrame(tick);
			return;
		}

		animating = false;

		if (pendingDismiss) {
			dismissNow();
		}
	}

	function animate() {
		var node = findRoot();

		if (node) {
			node.classList.add(SMOOTH_CLASS);
		}

		if (animating) {
			return;
		}

		animating = true;
		lastTick = window.performance.now();
		window.requestAnimationFrame(tick);
	}

	function setProgress(loaded, size) {
		current = loaded;
		total = size;

		if (size > 0) {
			ratio = Math.max(0, Math.min(1, loaded / size));
		}

		if (smoothingMs() > 0 && !failedFinish) {
			animate();
		} else {
			displayed = ratio;
			render(ratio);
		}

		for (var i = 0; i < progressHandlers.length; i++) {
			call(progressHandlers[i], [ratio, current, total]);
		}
	}

	function dismiss() {
		if (dismissed) {
			return;
		}

		if (awaitsFull()) {
			floorRatio = 1;
		}

		if (displayed < targetRatio()) {
			if (smoothingMs() > 0) {
				dismissCeiling = targetRatio();
				pendingDismiss = true;
				animate();
				return;
			}

			displayed = targetRatio();
			render(displayed);
		}

		dismissNow();
	}

	function dismissNow() {
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
		if (failed) {
			failedFinish = true;
		}

		if (finished) {
			if (failed) {
				dismissNow();
			}

			return;
		}

		finished = true;
		setProgress(1, 1);

		for (var i = 0; i < doneHandlers.length; i++) {
			call(doneHandlers[i], []);
		}

		if (failed) {
			dismissNow();
		} else if (api.mode === "on-engine-load") {
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

	window.EBS = api;

	function wrapEngine(engineClass) {
		if (!engineClass || engineClass.ebsWrapped || !engineClass.prototype) {
			return;
		}

		engineClass.ebsWrapped = true;

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
			console.warn("EBS: could not hook Engine, falling back to the shell status.", error);
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

		node.style.setProperty("--ebs-art-bottom", bottom.toFixed(1) + "px");
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
