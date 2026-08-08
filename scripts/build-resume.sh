#!/usr/bin/env bash

set -e

## Check for Typst

if ! command -v typst &> /dev/null; then
    echo "Typst is not installed."
    exit 1
fi

## Build the resume PDF

typst compile src/resume.typ data/original_media/Arcade.pdf

echo "Resume PDF built successfully!"