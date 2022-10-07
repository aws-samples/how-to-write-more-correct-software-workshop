#!/bin/bash

diff=$(comm -23 \
  <(sort exercises/complete/src/AwsKmsArnParsing.dfy | uniq) \
  <(sort instructions/*.md | uniq))

[ -z "$diff" ] || (echo "Content not in steps: $diff" && exit 1)

