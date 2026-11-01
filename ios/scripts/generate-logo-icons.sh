#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assets="$project_dir/Charalarm/Assets.xcassets"
source_logo="$assets/charalarm-logo.imageset/CharalarmLogo.png"

write_contents() {
    local directory="$1"
    local filename="$2"
    local icon_type="$3"
    if [ "$icon_type" = "appicon" ]; then
        cat > "$directory/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "$filename",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
    else
        cat > "$directory/Contents.json" <<EOF
{
  "images" : [ { "filename" : "$filename", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
    fi
}

# スプラッシュのロゴ全体を縦横比・色を保って白い正方形の中央に置く。
production="$assets/AppIcon-Logo-Production.appiconset"
mkdir -p "$production"
magick "$source_logo" -resize 900x -background white -gravity center \
    -extent 1024x1024 -alpha remove -alpha off -strip \
    "PNG24:$production/charalarm-logo-production.png"
write_contents "$production" charalarm-logo-production.png appicon

for environment in Develop Staging; do
    lower_environment="$(printf '%s' "$environment" | tr '[:upper:]' '[:lower:]')"
    directory="$assets/AppIcon-Logo-$environment.appiconset"
    filename="charalarm-logo-$lower_environment.png"
    banner_source="$assets/AppIcon-Shiori-$environment.appiconset/charalarm-$lower_environment.png"
    mkdir -p "$directory"
    # 既存の環境ラベルをそのまま使い、フォントや帯の見た目を揃える。
    magick "$production/charalarm-logo-production.png" \
        \( "$banner_source" -crop 1024x200+0+824 +repage \) \
        -gravity south -compose over -composite -strip "PNG24:$directory/$filename"
    write_contents "$directory" "$filename" appicon
done

preview="$assets/AppIconLogoPreview.imageset"
mkdir -p "$preview"
magick "$production/charalarm-logo-production.png" -resize 256x256 -strip \
    "PNG24:$preview/app-icon-logo-preview.png"
write_contents "$preview" app-icon-logo-preview.png imageset
