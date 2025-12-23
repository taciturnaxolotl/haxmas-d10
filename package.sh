#!/bin/bash

# Find and zip the files for LOVE
nix-shell -p zip --run 'find . -type f \( -name "*.lua" -o -name "*.png" -o -name "*.aseprite" \) -print | zip -@ haxmas-d10.love'

# Convert to web version using love.js
bunx love.js haxmas-d10.love haxmas-d10 -c

echo "Build complete! Deploy the haxmas-d10/ directory to Cloudflare."
