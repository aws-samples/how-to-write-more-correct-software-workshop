// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// Copied from https://github.com/aws/aws-encryption-sdk-dafny/blob/mainline/src/StandardLibrary/StandardLibrary.dfy

include "Wrappers.dfy"

module Util {
  import opened Wrappers

  function method {:tailrecursion} Join<T>(ss: seq<seq<T>>, joiner: seq<T>): (s: seq<T>)
    requires 0 < |ss|
  {
    if |ss| == 1 then ss[0] else ss[0] + joiner + Join(ss[1..], joiner)
  }

  function method {:tailrecursion} Split<T(==)>(s: seq<T>, delim: T): (res: seq<seq<T>>)
    ensures delim !in s ==> res == [s]
    ensures s == [] ==> res == [[]]
    ensures 0 < |res|
    ensures forall i :: 0 <= i < |res| ==> delim !in res[i]
    ensures Join(res, [delim]) == s
    decreases |s|
  {
    var i := FindIndexMatching(s, delim, 0);
    if i.Some? then [s[..i.value]] + Split(s[(i.value + 1)..], delim) else [s]
  }

  lemma WillSplitOnDelim<T>(s: seq<T>, delim: T, prefix: seq<T>)
    requires |prefix| < |s|
    requires forall i :: 0 <= i < |prefix| ==> prefix[i] == s[i]
    requires delim !in prefix && s[|prefix|] == delim
    ensures Split(s, delim) == [prefix] + Split(s[|prefix| + 1..], delim)
  {
    calc {
      Split(s, delim);
    ==
      var i := FindIndexMatching(s, delim, 0);
      if i.Some? then [s[..i.value]] + Split(s[i.value + 1..], delim) else [s];
    ==  { FindIndexMatchingLocatesElem(s, delim, 0, |prefix|); assert FindIndexMatching(s, delim, 0).Some?; }
      [s[..|prefix|]] + Split(s[|prefix| + 1..], delim);
    ==  { assert s[..|prefix|] == prefix; }
      [prefix] + Split(s[|prefix| + 1..], delim);
    }
  }

  lemma WillNotSplitWithOutDelim<T>(s: seq<T>, delim: T)
    requires delim !in s
    ensures Split(s, delim) == [s]
  {
    calc {
      Split(s, delim);
    ==
      var i := FindIndexMatching(s, delim, 0);
      if i.Some? then [s[..i.value]] + Split(s[i.value+1..], delim) else [s];
    ==  { FindIndexMatchingLocatesElem(s, delim, 0, |s|); }
      [s];
    }
  }

  lemma FindIndexMatchingLocatesElem<T>(s: seq<T>, c: T, start: nat, elemIndex: nat)
    requires start <= elemIndex <= |s|
    requires forall i :: start <= i < elemIndex ==> s[i] != c
    requires elemIndex == |s| || s[elemIndex] == c
    ensures FindIndexMatching(s, c, start) == if elemIndex == |s| then None else Some(elemIndex)
    decreases elemIndex - start
    {}

  function method FindIndexMatching<T(==)>(s: seq<T>, c: T, i: nat): (index: Option<nat>)
    requires i <= |s|
    ensures index.Some? ==>  i <= index.value < |s| && s[index.value] == c && c !in s[i..index.value]
    ensures index.None? ==> c !in s[i..]
    decreases |s| - i
  {
    FindIndex(s, x => x == c, i)
  }

  function method {:tailrecursion} FindIndex<T>(s: seq<T>, f: T -> bool, i: nat): (index: Option<nat>)
    requires i <= |s|
    ensures index.Some? ==> i <= index.value < |s| && f(s[index.value]) && (forall j :: i <= j < index.value ==> !f(s[j]))
    ensures index.None? ==> forall j :: i <= j < |s| ==> !f(s[j])
    decreases |s| - i
  {
    if i == |s| then None
    else if f(s[i]) then Some(i)
    else FindIndex(s, f, i + 1)
  }
}