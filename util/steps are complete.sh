#!/bin/bash

diff=$(comm -23 \
  <(sort exercises/complete/src/AwsKmsArnParsing.dfy | uniq) \
  <(sort ./instructions/steps.md | uniq))

[ -z "$diff" ] || (echo $diff && exit 1)