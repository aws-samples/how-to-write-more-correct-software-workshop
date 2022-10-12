[//]: # "Copyright Amazon.com Inc. or its affiliates. All Rights Reserved."
[//]: # "SPDX-License-Identifier: CC-BY-SA-4.0"

<!-- !test program
tmpdir=$(mktemp -d)
tmpProgram="$tmpdir/program.dfy"
cat > $tmpProgram

sort $tmpProgram | uniq > $tmpdir/sort
sort ./exercises/complete/src/AwsKmsArnParsing.dfy | uniq > $tmpdir/check
diff=$(comm -23 $tmpdir/sort $tmpdir/check)
[ -z "$diff" ] || (echo $diff && exit 1)
-->

Welcome! 
We're continuing to take you through the process of implementing
example specification in the verification-aware programming language Dafny.

These steps assume that you have already completed everything in [here](steps.md).

## Step 15

Again looking at our specification
we need to handle an AWS KMS identifier.
This is covered in sections 2.8 and 2.9.
This adds some complexity.
Since a raw key id is not a complete resource section.

So let's throw up the last of our implementation as stubs:

<!-- !test check Identifier stubs -->
```dafny

  datatype AwsKmsIdentifier =
    | AwsKmsArnIdentifier(a: AwsKmsArn)
    | AwsKmsRawResourceIdentifier(r: AwsKmsResource)

  function ParseAwsKmsIdentifier(identifier: string)
    : (result: Result<AwsKmsIdentifier, string>)

  function ParseAwsKmsRawResource(identifier: string)
    : (result: Result<AwsKmsResource, string>)

  //= aws-kms-key-arn.txt#2.8
  //= type=implication
  //# This function MUST take a single AWS KMS ARN
  //# If the input is an invalid AWS KMS ARN this function MUST error.
  predicate MultiRegionAwsKmsArn?(arn: AwsKmsArn)

  //= aws-kms-key-arn.txt#2.9
  //= type=implication
  //# This function MUST take a single AWS KMS identifier
  predicate MultiRegionAwsKmsIdentifier?(identifier: AwsKmsIdentifier)

  predicate MultiRegionAwsKmsResource?(resource: AwsKmsResource)

```

What is going on here?!

As promised we have a `datatype` with multiple constructors.
You can see that we reference the type here `: (result: Result<AwsKmsIdentifier, string>)`.
In that function we will need to create
either a `AwsKmsArnIdentifier(a)` or a `AwsKmsRawResourceIdentifier(r)`.
This is how you define a "Discriminated Union" in Dafny.
That's just a fancy way of saying "An A or a B" :)

## Step 16

Let's do `ParseAwsKmsIdentifier` first.
How can we distinguish an ARN
from a resource?
Let's go with "It starts with arn:".

<!-- !test check ParseAwsKmsIdentifier -->
```dafny

  function ParseAwsKmsIdentifier(identifier: string)
    : (result: Result<AwsKmsIdentifier, string>)
  {
    if "arn:" <= identifier then
      var arn :- ParseAwsKmsArn(identifier);
      Success(AwsKmsArnIdentifier(arn))
    else
      var r :- ParseAwsKmsRawResource(identifier);
      Success(AwsKmsRawResourceIdentifier(r))
  }

```

## Step 17

Lets do `ParseAwsKmsRawResource`.
First we will do a quick naive implementation.

```dafny

  function ParseAwsKmsRawResource(identifier: string)
    : (result: Result<AwsKmsResource, string>)
  {
    if "alias/" <= identifier then
      ParseAwsKmsResource(identifier)
    else
      :- Need(!("key/" <= identifier), "Malformed raw key id: " + identifier);
      var resource := AwsResource(
        resourceType := "key",
        value := identifier
      );

      Success(resource)
  }

```

Hmm, so Dafny does not believe us.
Let's see,
does it believe
```dafny
assert resource.resourceType == "key";
```

Hmm, so what is the other condition then?
```dafny
assert 0 < |resource.value|;
```

Yup! Oh, right, if `identifier == "key\"`
then `0 == |resource.value|`!
Notice how the error message moved
from the `Success` to the `assert`.
Where the Dafny error message is
also gives us information we can use.

This does NOT mean that the `Success` magically became correct!
Dafny is just telling you that IF `0 < |resource.value|` is true,
the return value is correct.
It is important to keep in mind that all of these assertions are connected,
and if any single assertion is not proven,
it means you can't necessarily trust the proof of any others.

Now we could use `ParseAwsKmsResource`
but that has a bunch of redundant string operations.
Let's just add the condition to our existing `Need`:

<!-- !test check ParseAwsKmsRawResource complete -->
```dafny

  function ParseAwsKmsRawResource(identifier: string)
    : (result: Result<AwsKmsResource, string>)
  {
    if "alias/" <= identifier then
      ParseAwsKmsResource(identifier)
    else
      :- Need(!("key/" <= identifier) && 0 < |identifier|, "Malformed raw key id: " + identifier);
      var resource := AwsResource(
        resourceType := "key",
        value := identifier
      );

      Success(resource)
  }

```

## Step 18
We are almost done with our implementation!!

First `MultiRegionAwsKmsArn?`

<!-- !test check MultiRegionAwsKmsArn? -->
```dafny

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
    //# If the resource type is "key" and the resource ID starts with
    //# "mrk-", this is a AWS KMS multi-Region key ARN and MUST return true.
    ensures
      && arn.resource.resourceType == "key"
      && "mrk-" <= arn.resource.value
    ==>
      MultiRegionAwsKmsArn?(arn)

    //= aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If the resource type is "key" and the resource ID does not start with "mrk-",
    //# this is a (single-region) AWS KMS key ARN and MUST return false.
    ensures
      && arn.resource.resourceType == "key"
      && !("mrk-" <= arn.resource.value)
    ==>
      !MultiRegionAwsKmsArn?(arn)
  {
    MultiRegionAwsKmsResource?(arn.resource)
  }

```

The most interesting thing here
is that we are doing what looks like a recursive call
in our `ensures` clause.
This is not actually recursive.
This is because we did not give our `predicate` a named result.
This is just telling Dafny what to expect about the result.

Again, Dafny is complaining because
it does not know anything about `MultiRegionAwsKmsResource?`.
Let's just add it this time.

This is always a `key` that starts with `mrk-`.
Given everything we have learned we have:

<!-- !test check MultiRegionAwsKmsResource? -->
```dafny

  predicate MultiRegionAwsKmsResource?(resource: AwsKmsResource)
  {
    && resource.resourceType == "key"
    && "mrk-" <= resource.value
  }

```

Notice all the Dafny errors went away.
Dafny was able to look inside `MultiRegionAwsKmsResource?`
and see that these conditions would be correct.
This transparency of `function`s can be powerful.
But Dafny can not unroll every function.

Finally, `MultiRegionAwsKmsIdentifier?`!

<!-- !test check MultiRegionAwsKmsIdentifier? -->
```dafny

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

```

This `match` expression looks at the possible constructors of `AwsKmsIdentifier`
and creates a branch for each one.
If say `AwsKmsArnIdentifier` had more arguments,
then we would be required to list them all.
The arguments bind variables that are in scope
in that `case` branch.

## Step 19

Wait!
Run `make duvet_report` and notice the command still fails.
Click "Compliance Coverage Report" in the header bar of the report
to navigate back to the top.

We are missing some proof.
Section 2.9.

Well, the function takes an `AwsKmsIdentifier`,
but it is specified from the `string`.
This would be a little complicated
to handle directly in `MultiRegionAwsKmsIdentifier?`.

Dafny has another tool,
a `lemma`.
This is like a running _every_ test all at once.
In logic a lemma is a little proof.
Something that is used on the way to prove
what you really care about.

This is how it is used in Dafny.
We want correct programs,
but sometimes we need to prove parts.


We will start by proving that `MultiRegionAwsKmsIdentifier?` is correct.
Start here:

<!-- !test check MultiRegionAwsKmsIdentifier?Correct signature -->
```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(identifier: string)

```

We name the `lemma` to relate it to `MultiRegionAwsKmsIdentifier?`.
It takes a `string` because our requirements
are described as strings.
Incidentally this is because when you configure AWS KMS keys
they are strings.
Because we have not placed _any_ conditions on this `string`
it represents _any_ string.
This means every length,
and every combination of characters.

So anything that this `lemma` will ensure
is like a test on every possible `string` all at once!

However our `predicate` takes an `AwsKmsIdentifier`.
This means that not _every_ string is valid input.
We want to shape our input.
Instead of dealing with every possible string,
we want to deal with every string that could be a `AwsKmsIdentifier`.

For this we need a precondition.
Something that MUST be true *before* the function is evaluated.
Dafny expresses this with the keyword `requires`:

<!-- !test check MultiRegionAwsKmsIdentifier?Correct with requires -->
```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(identifier: string)
    requires ParseAwsKmsIdentifier(identifier).Success?

```

Now everywhere we can assume that the string `s`
is a valid `AwsKmsIdentifier`!
This simplifies our first requirement:

<!-- !test check MultiRegionAwsKmsIdentifier?Correct first ensures -->
```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(identifier: string)
    requires ParseAwsKmsIdentifier(identifier).Success?

    //= aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts with "arn:", this MUST return the output of
    //# identifying an an AWS KMS multi-Region ARN (Section 2.8) called with this
    //# input.
    ensures "arn:" <= identifier
      ==>
        var arnIdentifier := ParseAwsKmsIdentifier(identifier).value;
        MultiRegionAwsKmsIdentifier?(arnIdentifier) == MultiRegionAwsKmsArn?(arnIdentifier.a)
  {}

```

Dafny uses the fact that the string `ParseAwsKmsIdentifier` will succeed
with the fact that this string starts with `arn:`
to know that `ParseAwsKmsArn` MUST succeed.
We can then wrap this `arn` so that we can compare the two calls
as the specification requires.

Looking at our specification,
our next two requirements are very similar.
They differ in how the string should start
and if `MultiRegionAwsKmsIdentifier?` should return true or false

<!-- !test check MultiRegionAwsKmsIdentifier?Correct other requirements -->
```dafny

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

```

Finally the specification says
"If the input does not start with any of the above,
this is not a multi-Region key id and MUST return false."
This is just a negation of the three starts with we already have.

There are a few ways to express this,
but this one mirrors the specification to make it easier
to see the correspondence.

<!-- !test check MultiRegionAwsKmsIdentifier?Correct final ensures -->
```dafny

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

```

Putting that all together we get.

<!-- !test check MultiRegionAwsKmsIdentifier?Correct complete -->
```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(identifier: string)
    requires ParseAwsKmsIdentifier(identifier).Success?

    //= aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts with "arn:", this MUST return the output of
    //# identifying an an AWS KMS multi-Region ARN (Section 2.8) called with this
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

```

## Step 20

Let's run Duvet one last time:

```bash
make duvet_report
```

Success! The command no longer fails
(if you don't believe the lack of error messages, you can check with `echo $?`)
and the report is a happy sea of green.
Congratulations on your formally-verified implementation!

Again we can run our code!
Before we ran `ParseAwsKmsArn` in our test.
But now we have a more complete function `ParseAwsKmsIdentifier`.
We can update `Index.dfy` to use this other function.

```dafny

      var output := AwsKmsArnParsing.ParseAwsKmsIdentifier(args[i]);

```

Now, as before 

```bash
make execute
```

In our makefile there are targets for each supported runtime.
Feel free to play around with other values!
You can also swap back and forth between the parsing functions.
