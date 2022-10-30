#!/bin/bash
set -eo pipefail

staticAssets=(
	"css"
	"fonts"
	"LICENSE"
)

# Clear the output directory so that we start fresh.
mkdir -p out
rm -rf out/*

# Translate each index.md Markdown file into the corresponding HTML file.
for mdFilePath in `find . -name index.md`
do
  parentDir=$(dirname "${mdFilePath}")
  mkdir -p "out/${parentDir}"
  outFilePath="out/${parentDir}/index.html"

  echo ">> translating ${mdFilePath} -> ${outFilePath}"
  pandoc --template meta/generic-template.html --lua-filter=filter.lua "${mdFilePath}" \
    -o "${outFilePath}"
done

indexFileContents="---\ntitle: Ashay Rane\n---\n[about](/about)\n\n# Ashay Rane #\n***"

# Translate each Markdown file into the corresponding HTML file.
for mdFilePath in `find . -name \*.md | grep -v /index.md | sort -nr`
do
  parentDir=$(dirname "${mdFilePath}")
  baseFileName=$(basename "${mdFilePath}")
  baseFileNameWithoutExt="${baseFileName%%.*}"

  webDir="${parentDir}/${baseFileNameWithoutExt}"
  outFilePath="out/${webDir}/index.html"
  mkdir -p $(dirname "${outFilePath}")

  echo ">> translating ${mdFilePath} -> ${outFilePath}"
  if echo "${mdFilePath}" | grep --quiet "^./blog/";
  then
    date=$(echo "${parentDir}" | sed 's/^\.\/blog\/\(.*\)\/\(.*\)\/\(.*\)$/\1-\2-\3/')
    title=$(head -n10 "${mdFilePath}" | grep title: | head -n1 | cut -d: -f2 | xargs)
    indexFileContents="${indexFileContents}\n<div class=\"post\"><div class=\"post-date\">${date}</div><div class=\"post-title\">[${title}](${webDir})</div></div>"

    pandoc --template meta/blog-post-template.html --lua-filter=filter.lua \
      "${mdFilePath}" -o "${outFilePath}"
  else
    pandoc --template meta/generic-template.html --lua-filter=filter.lua \
      "${mdFilePath}" -o "${outFilePath}"
  fi
done

echo ">> writing out/index.html"
echo -e "${indexFileContents}" | pandoc --template meta/generic-template.html --lua-filter=filter.lua -o "out/index.html"

# Copy any HTML files as they are.
for htmlFilePath in `find . -name \*.html | grep -v "^./meta" | grep -v "^./out"`
do
  mkdir -p $(dirname "${htmlFilePath}")
  outFilePath="out/${htmlFilePath}"

  echo ">> copying ${htmlFilePath} -> ${outFilePath}"
  cp "${htmlFilePath}" "${outFilePath}"
done

# Copy other static assets.
for staticFilePath in "${staticAssets[@]}"
do
  mkdir -p $(dirname "${staticFilePath}")
  outFilePath="out/${staticFilePath}"

  echo ">> copying ${staticFilePath} -> ${outFilePath}"
  cp -r "${staticFilePath}" "${outFilePath}"
done
