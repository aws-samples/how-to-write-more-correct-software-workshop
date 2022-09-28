// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

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
  {
    var components := Split(identifier, ':');

    var resource := ParseAwsKmsResources(components[5]);

    var arn := AwsArn(
      arnLiteral := components[0],
      partition := components[1],
      service := components[2],
      region := components[3],
      account := components[4],
      resource := resource
    );

    Success(arn)
  }

  function ParseAwsKmsResources(identifier: string)
    : (result: AwsKmsResource)



}
