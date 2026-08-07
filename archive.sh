cd "$(dirname "$0")"

plugin_cfg="addons/itch_loading_indicator_page/plugin.cfg"
version="$(sed -n 's/^version="\(.*\)"$/\1/p' "$plugin_cfg")"

if [ -z "$version" ]; then
	echo "No version found in $plugin_cfg" >&2
	exit 1
fi

mkdir -p dist
git archive --prefix=ilip/ -o "./dist/ilip_${version}.zip" HEAD
echo "Export successful! (dist/ilip_${version}.zip)"