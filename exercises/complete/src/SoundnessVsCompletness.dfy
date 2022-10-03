// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

include "./AwsKmsArnParsing.dfy"

module {:options "-functionSyntax:4"} SoundnessVsCompletness {
  import opened Wrappers
  import opened Util
  import opened AwsKmsArnParsing


  lemma ParseAwsKmsIdentifierIsComplete(s: string)
    requires ParseAwsKmsIdentifier(s).Success?
    ensures s == AwsKmsIdentifierToString(ParseAwsKmsIdentifier(s).value)
  {
    if
      && ParseAwsKmsIdentifier(s).value.AwsKmsRawResourceIdentifier?
      && s != AwsKmsIdentifierToString(ParseAwsKmsIdentifier(s).value) {

    }

    if
      && ParseAwsKmsIdentifier(s).value.AwsKmsArnIdentifier?
      && s != AwsKmsIdentifierToString(ParseAwsKmsIdentifier(s).value)
    {
      var arn := ParseAwsKmsIdentifier(s).value.a;
      assert [
          arn.arnLiteral,
          arn.partition,
          arn.service,
          arn.region,
          arn.account,
          Split(s, ':')[5]
        ] == Split(s, ':');
    }
  }

  function AwsKmsIdentifierToString(identifier: AwsKmsIdentifier)
    : (output: string)
  {
    match identifier
      case AwsKmsArnIdentifier(arn) => AwsKmsArnToString(arn)
      case AwsKmsRawResourceIdentifier(resource) => AwsKmsRawResourceToString(resource)
  }

  function AwsKmsArnToString(arn: AwsKmsArn)
    : (output: string)
  {
    Join([
        arn.arnLiteral,
        arn.partition,
        arn.service,
        arn.region,
        arn.account,
        arn.resource.resourceType + "/" + arn.resource.value
      ],
      ":"
    )
  }

  function AwsKmsRawResourceToString(resource: AwsKmsResource)
    : (output: string)
  {
    if resource.resourceType == "alias" then
      resource.resourceType + "/" + resource.value
    else
      resource.value
  }

}