// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

include "../../dafny-helpers/include.dfy"

module {:options "-functionSyntax:4"} AwsKmsArnParsing {

  import opened Wrappers
  import opened Util

  datatype AwsArn = AwsArn(
    nameonly arnLiteral: string,
    nameonly partition: string,
    nameonly service: string,
    nameonly region: string,
    nameonly account: string,
    nameonly resource: AwsResource
  )

  datatype AwsResource = AwsResource(
    nameonly resourceType: string,
    nameonly value: string
  )

  predicate AwsArn?(arn:AwsArn)
  {
    && arn.arnLiteral == "arn"
    && 0 < |arn.partition|
    && 0 < |arn.service|
    && 0 < |arn.region|
    && 0 < |arn.account|
    && AwsResource?(arn.resource)
  }

  predicate AwsResource?(resource:AwsResource)
  {
    && 0 < |resource.value|
  }

  predicate AwsKmsArn?(arn:AwsArn)
  {
    && AwsArn?(arn)
    && arn.service == "kms"
    && AwsKmsResource?(arn.resource)
  }

  predicate AwsKmsResource?(resource:AwsResource)
  {
    && AwsResource?(resource)
    && (
      || resource.resourceType == "key"
      || resource.resourceType == "alias"
      )
  }

  type AwsKmsArn = arn: AwsArn
  | AwsKmsArn?(arn)
  witness *

  type AwsKmsResource = resource: AwsResource
  | AwsKmsResource?(resource)
  witness *

  function ParseAwsKmsArn(identifier: string)
    : (result: Result<AwsKmsArn, string>)

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# A string with 5 ":" that MUST delimit following 6 parts:
    ensures result.Success? ==> |Split(identifier, ':')| == 6

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# MUST start with string "arn"
    ensures result.Success? ==> "arn" <= identifier

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The partition MUST be a non-empty
    ensures result.Success? ==> 0 < |Split(identifier, ':')[1]|

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The service MUST be the string "kms"
    ensures result.Success? ==> Split(identifier, ':')[2] == "kms"

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The region MUST be a non-empty string
    ensures result.Success? ==> 0 < |Split(identifier, ':')[3]|

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The account MUST be a non-empty string
    ensures result.Success? ==> 0 < |Split(identifier, ':')[4]|

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The resource section MUST be non-empty.
    ensures result.Success? ==> 0 < |Split(identifier, ':')[5]|

  {
    var components := Split(identifier, ':');

    :- Need(6 == |components|, "Malformed arn: " + identifier);

    var resource :- ParseAwsKmsResources(components[5]);

    var arn := AwsArn(
      arnLiteral := components[0],
      partition := components[1],
      service := components[2],
      region := components[3],
      account := components[4],
      resource := resource
    );

    :- Need(AwsKmsArn?(arn), "Malformed Arn:" + identifier);

    Success(arn)
  }

  function ParseAwsKmsResources(arnResource: string)
    : (result: Result<AwsKmsResource, string>)

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# It MUST be split by a
    //# single "/" any additional "/" are included in the resource id
    ensures result.Success?
    ==>
      && '/' in arnResource
      && arnResource == result.value.resourceType + "/" + result.value.value

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The resource type MUST be either "alias" or "key"
    //# The resource id MUST be a non-empty string
    ensures result.Success?
    ==>
      ("key/" < arnResource || "alias/" < arnResource)
   {
    var info := Split(arnResource, '/');

    :- Need(1 < |info|, "Malformed resource: " + arnResource);

    var resourceType := info[0];
    var value := Join(info[1..], "/");

    var resource := AwsResource(
      resourceType := resourceType,
      value := value
    );

    :- Need(AwsKmsResource?(resource), "Malformed resource: " + arnResource);

    Success(resource)
  }

  function ParseAwsKmsRawResources(identifier: string)
    : (result: Result<AwsKmsResource, string>)
  {
    if "alias/" <= identifier then
      ParseAwsKmsResources(identifier)
    else
      :- Need(!("key/" <= identifier) && 0 < |identifier|, "Malformed raw key id: " + identifier);
      var resource := AwsResource(
        resourceType := "key",
        value := identifier
      );

      Success(resource)
  }

  datatype AwsKmsIdentifier =
    | AwsKmsArnIdentifier(a: AwsKmsArn)
    | AwsKmsRawResourceIdentifier(r: AwsKmsResource)

  function ParseAwsKmsIdentifier(identifier: string)
    : (result: Result<AwsKmsIdentifier, string>)
  {
    if "arn:" <= identifier then
      var arn :- ParseAwsKmsArn(identifier);
      Success(AwsKmsArnIdentifier(arn))
    else
      var r :- ParseAwsKmsRawResources(identifier);
      Success(AwsKmsRawResourceIdentifier(r))
  }

  //= aws-kms-key-arn.txt#2.8
  //= type=implication
  //# This function MUST take a single AWS KMS ARN
  //# If the input is an invalid AWS KMS ARN this function MUST error.
  predicate MultiRegionAwsKmsArn?(arn: AwsKmsArn)

    //= aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If resource type is "alias", this is an AWS KMS alias ARN and MUST
    //# return false.
    ensures arn.resource.resourceType == "alias" ==> !MultiRegionAwsKmsArn?(arn)

    //= aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If resource type is "key" and resource ID starts with
    //# "mrk-", this is a AWS KMS multi-Region key ARN and MUST return true.
    ensures
      && arn.resource.resourceType == "key"
      && "mrk-" <= arn.resource.value
    ==>
      MultiRegionAwsKmsArn?(arn)

    //= aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If resource type is "key" and resource ID does not start with "mrk-",
    //# this is a (single-region) AWS KMS key ARN and MUST return false.
    ensures
      && arn.resource.resourceType == "key"
      && !("mrk-" <= arn.resource.value)
    ==>
      !MultiRegionAwsKmsArn?(arn)
  {
    MultiRegionAwsKmsResource?(arn.resource)
  }

  //= aws-kms-key-arn.txt#2.9
  //= type=implication
  //# This function MUST take a single AWS KMS identifier
  predicate MultiRegionAwsKmsIdentifier?(identifier: AwsKmsIdentifier)
  {
    match identifier {
      case AwsKmsArnIdentifier(arn) =>
        MultiRegionAwsKmsArn?(arn)
      case AwsKmsRawResourceIdentifier(r) =>
        MultiRegionAwsKmsResource?(r)
    }
  }

  predicate MultiRegionAwsKmsResource?(resource: AwsKmsResource)
  {
    && resource.resourceType == "key"
    && "mrk-" <= resource.value
  }

  lemma MultiRegionAwsKmsIdentifier?Correct(identifier: string)
    requires ParseAwsKmsIdentifier(identifier).Success?

    //= aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts with "arn:", this MUST return the output of
    //# identifying an an AWS KMS multi-Region ARN (aws-kms-key-
    //# arn.md#identifying-an-an-aws-kms-multi-region-arn) called with this
    //# input.
    ensures "arn:" <= identifier
      ==>
        var arnIdentifier := ParseAwsKmsIdentifier(identifier).value;
        MultiRegionAwsKmsIdentifier?(arnIdentifier) == MultiRegionAwsKmsArn?(arnIdentifier.a)

    //= aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts with "alias/", this an AWS KMS alias and
    //# not a multi-Region key id and MUST return false.
    ensures "alias/" <= identifier
      ==>
        var resource := ParseAwsKmsIdentifier(identifier).value;
        !MultiRegionAwsKmsIdentifier?(ParseAwsKmsIdentifier(identifier).value)

    //= aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts
    //# with "mrk-", this is a multi-Region key id and MUST return true.
    ensures "mrk-" <= identifier
      ==>
        var resource := ParseAwsKmsIdentifier(identifier).value;
        MultiRegionAwsKmsIdentifier?(resource)

    //= aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If
    //# the input does not start with any of the above, this is not a multi-
    //# Region key id and MUST return false.
    ensures
        && !("arn:" <= identifier )
        && !("alias/" <= identifier )
        && !("mrk-" <= identifier )
      ==>
        var resource := ParseAwsKmsIdentifier(identifier);
        !MultiRegionAwsKmsIdentifier?(resource.value)
  {}

}
