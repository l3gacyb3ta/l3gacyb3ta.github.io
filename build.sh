#!/bin/bash

set -e

rm -f bin/aethopica
rm -rf out
mkdir out
mkdir out/site out/links out/media 

cp -r data/links/* out/links
cp -r data/media/* out/media


cc src/main.c -g -O0 -std=c89 -DLOCALRUN -Wall -Wno-unknown-pragmas -o bin/aethopica 

cd data

../bin/aethopica

# rm -f ./bin/aethopica