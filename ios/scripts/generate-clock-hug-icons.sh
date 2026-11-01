#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assets="$project_dir/Charalarm/Assets.xcassets"
# 承認済みのベージュ・余白調整版を Production の原本として保持する。
source_icon="$assets/AppIcon-ClockHug-Production.appiconset/charalarm-clock-hug-production.png"

write_appicon_contents() {
    local directory="$1"
    local filename="$2"
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
}

write_appicon_contents "$(dirname "$source_icon")" charalarm-clock-hug-production.png

for environment in Develop Staging; do
    lower_environment="$(printf '%s' "$environment" | tr '[:upper:]' '[:lower:]')"
    directory="$assets/AppIcon-ClockHug-$environment.appiconset"
    filename="charalarm-clock-hug-$lower_environment.png"
    banner_source="$assets/AppIcon-Shiori-$environment.appiconset/charalarm-$lower_environment.png"
    mkdir -p "$directory"
    # 上部824pxに絵全体を収めてから、既存と同じ環境ラベルを合成する。
    magick "$source_icon" -resize 824x824 -virtual-pixel edge \
        -set option:distort:viewport 1024x1024-100+0 -filter point -distort SRT 0 +repage \
        \( "$banner_source" -crop 1024x200+0+824 +repage \) \
        -gravity south -compose over -composite -strip "PNG24:$directory/$filename"
    write_appicon_contents "$directory" "$filename"
done

preview="$assets/AppIconClockHugPreview.imageset"
mkdir -p "$preview"
magick "$source_icon" -resize 256x256 -strip "PNG24:$preview/app-icon-clock-hug-preview.png"
cat > "$preview/Contents.json" <<EOF
{
  "images" : [ { "filename" : "app-icon-clock-hug-preview.png", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
