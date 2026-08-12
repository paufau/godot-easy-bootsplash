cd "$(dirname "$0")"

plugin_cfg="addons/easy_bootsplash/plugin.cfg"
version="$(sed -n 's/^version="\(.*\)"$/\1/p' "$plugin_cfg")"

if [ -z "$version" ]; then
	echo "No version found in $plugin_cfg" >&2
	exit 1
fi

mkdir -p dist
git archive --prefix=easy_bootsplash/ -o "./dist/easy_bootsplash_${version}.zip" HEAD
echo "Export successful! (dist/easy_bootsplash_${version}.zip)"