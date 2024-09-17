#!/bin/bash

set -e

./batchVariants.sh

rm -rf bin out out/links out/media
mkdir bin out out/links out/media

cp -r data/media/* out/media && cp -r data/links/* out/links

cc src/main.c -g -O0 -std=c89 -Wall -Wno-unknown-pragmas -o bin/aethopica 

cd data && ../bin/aethopica

# rm -f ./bin/aethopica