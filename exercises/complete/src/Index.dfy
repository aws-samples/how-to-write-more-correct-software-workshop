// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

include "AwsKmsArnParsing.dfy"

module Main {

  import AwsKmsArnParsing

  method Main(rawArgs: seq<string>) {
    if 0 == |rawArgs| {
      print "Noting to parse\n";
      return;
    }
    var args := rawArgs[1..];
    for i := 0 to |args| {
      var output := AwsKmsArnParsing.ParseAwsKmsArn(args[i]);
      print output;
      print "\n";
    }
  }

}