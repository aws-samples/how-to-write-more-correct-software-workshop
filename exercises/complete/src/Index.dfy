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
      var output := AwsKmsArnParsing.ParseAwsKmsIdentifier(args[i]);
      print output;
      print "\n";
    }
  }

}