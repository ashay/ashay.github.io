#!/bin/bash
set -eo pipefail

staticAssets=(
	"css"
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
  pandoc --template meta/template.html --lua-filter=filter.lua "${mdFilePath}" \
    -o "${outFilePath}"
done

# Translate each Markdown file into the corresponding HTML file.
for mdFilePath in `find . -name \*.md | grep -v /index.md`
do
  parentDir=$(dirname "${mdFilePath}")
  baseFileName=$(basename "${mdFilePath}")
  baseFileNameWithoutExt="${baseFileName%%.*}"

  outFilePath="out/${parentDir}/${baseFileNameWithoutExt}/index.html"
  mkdir -p $(dirname "${outFilePath}")

  echo ">> translating ${mdFilePath} -> ${outFilePath}"
  pandoc --template meta/template.html --lua-filter=filter.lua "${mdFilePath}" \
    -o "${outFilePath}"
done

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
