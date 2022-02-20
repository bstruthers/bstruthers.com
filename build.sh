#!/bin/bash

# Remove the existing distributable
if [[ -d "dist" ]]; then
    rm -rf dist
fi

# Copy in the latest build
# TODO: pull from github release
cp -r ../nx-weblog/dist/apps/blog dist

# Copy latest assets
cp -r assets dist/

# Update the html with the meta tags, etc
head -2 dist/index.html > 1
tail -7 dist/index.html > 3
cat 1 index.tmpl 3 > dist/index.html
rm 1 3
