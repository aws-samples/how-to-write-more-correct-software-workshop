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

## Step 1

In VSCode open the directory `exercises/start`
and open the file `exercises/start/src/AwsKmsArnParsing.dfy`

You should see

<!-- !test check prelude -->
```dafny

// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

include "../../dafny-helpers/include.dfy"

module {:options "-functionSyntax:4"} AwsKmsArnParsing {

  import opened Wrappers
  import opened Util

}


```

1. `include` is how Dafny includes other files.
The file `include.dfy` is a helper file we added for you.

1. `module` is how Dafny organizes code.
This `module` is called `AwsKmsArnParsing`.
Everything in `{}` is the contents of the `module`.
Dafny does have ways to control what gets exported,
but for now, lets just say everything is exported.

1. `import` takes a named module
and bring it into scope.

1. `opened` takes all the exported names
in the imported module and puts them in the current namespace.
This is where we will get symbols that don't exist in this file,
for example `Split` and `Join`.

1. `{:options "-functionSyntax:4"}`
This is to simplify upgrading.
When Dafny v4 is released out modules with this option
will "Just Work".
If you are *really* interested:
see [Controlling language features
](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-controlling-language) for more details.

## Step 2

Since we are dealing with correct software,
we need a definition of correctness!
We have given you a specification `aws-kms-key-arn.txt`.
This has been lightly edited from [AWS Encryption SDK](https://github.com/awslabs/aws-encryption-sdk-specification/blob/master/framework/aws-kms/aws-kms-key-arn.md).

Currently `duvet` is optimized to handle RFC style (ITEF) files.
We have converted the markdown specification into this format for you.
Soon, `duvet` will support markdown more directly.

`duvet` can read text documents
and extract MUST/SHOULD ([RFC-2119](https://datatracker.ietf.org/doc/html/rfc2119) normative language) as requirements.
`duvet` will now keep track of this list for us.
It will ensure not only that we account every requirement,
but that we also provide some evidence that implemented requirements are correct. You will see how this work in more detail later.

In VSCode open a terminal and `cd exercises/start`.
Now let's extract the requirements and run a report.
We have made nice `make` targets for you.

```bash

make duvet_extract
make duvet_report

```

This fails because we have not even started.
Open the `compliance_report.html` in a browser.
You will see that we have a total of 20 requirements
for our `aws-kms-key-arn` specification.

Click on the specification and you can see details on these requirements.
We will start on section `2.5` so go ahead
and click on a 2.5 and take a second to read the specification.

## Step 3

Since we are going to be parsing strings,
we need some containers to put the parts of the strings in.

Paste the following code into the module
and then we will go over what it means.

```dafny

  datatype AwsArn = AwsArn
  datatype AwsResource = AwsResource

  predicate AwsArn?(arn:AwsArn)
  predicate AwsResource?(resource:AwsResource)
  predicate AwsKmsArn?(arn:AwsArn)
  predicate AwsKmsResource?(resource:AwsResource)

```

A `datatype` is an immutable container.
They are used to organize data.
We will add properties to them to hold our strings.

To the left of the `=` is the name of the `datatype`.
To the right of the `=` are the `datatype`'s constructors.
In this case, we have only one.
Later we will have more.

What is a `predicate` and what's the deal with that`?` at the end?
A `predicate` is a function that returns a `boolean`.
It is syntactic sugar for `function AwsArn?(arn:AwsArn) : bool`.

Generally such functions ask a question.
For example "Is this AwsArn `arn` a valid AwsArn?".
Since `?` is a perfectly good character for a name in Dafny,
it is often added to a `predicate`.
This also nicely binds the intention `predicate` with the `datatype`.

Dafny is perfectly happy with constructs that have no body.
We will use this later.

## Step 4

Let's add some properties to our `datatype`s.

<!-- !test check container datatypes -->
```dafny
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
```

Much like other languages,
every argument given to a `datatype` constructor
is a property.
This means that if the variable `obj` is an `AwsArn`
then `obj.service` is a `string`.
But what about `nameonly`?

`nameonly` forces callers to use named parameters.
This makes the call more verbose,
but it makes it much more readable.

You are not required to use it
in your code,
but I highly recommend it.

## Step 5

Now we have some containers.
Let's talk about the correct values for these containers.

<!-- !test check AwsArn? -->
```dafny

  predicate AwsArn?(arn:AwsArn)
  {
    && arn.arnLiteral == "arn"
    && 0 < |arn.partition|
    && 0 < |arn.service|
    && 0 < |arn.region|
    && 0 < |arn.account|
    && AwsResource?(arn.resource)
  }

```

We are evaluating the `AwsArn` container
to see if it is correct.
We can read this `predicate` as:
The arnLiteral MUST be the string "arn"
and partition, service, region, and account
MUST NOT be empty string
and finally the resource MUST be a correct AwsResource.

A `predicate` is a kind of function.
Functions in Dafny are just syntactic sugar for expressions.
You will note that there is no `;`.
The return value for any `predicate` or `function`
is just the vary last unterminated expression.

The leading token, `&&`, is just sugar.
Leading boolean operators like this
lets you reorder things nicely.
It may look strange at first,
but leading tokens like this grow on you.

`string`s in Dafny are a sequence of characters.
Surrounding a sequence with `|` will return the length (cardinality) or of a sequence.
So `0 < arn.partition.length`
is probably how you would expect that to be written
in a language you are more familiar with.

We are calling `AwsResource?`
even though it does not have an implementation.
If you tried to compile this,
Dafny would complain.
But all Dafny needs for `AwsArn?` to be valid
is to be able to prove that it will always return a `bool`.
Feel free to change `AwsResource?` to a function
that returns something else and see :)
`function AwsResource?(resource: AwsResource): string`

## Step 6

Using what we have learned,
let's add implementations to our remaining three `predicate`s .

<!-- !test check remaining correctness predicates -->
```dafny

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

```

Like `&&` is logical and, `||` is logical or.
So the resourceType for an `AwsKmsResource`
MUST be either "key" or "alias".

Go back and take a look at our specification.
Does this seem to capture most of what the specification says makes a valid AWS KMS ARN?

## Step 7

Many languages have types similar to Dafny's `datatype`,
albeit not always immutable.
These types have a quality of correctness.
After all, you can't put a number into a string.

A subset type lets us combine the correctness we defined
in our `predicate`s with a base `datatype`.
We can then reason about this new type statically.
If most types represent the basic shape of your data,
then Dafny's subset type is a painting
full of light, shadow, and color.

As we will see,
to return a subset type we will need to prove
that the `datatype` has been constructed correctly.
But after that this correctness in baked into the type.

Let's create one!

<!-- !test check AwsKmsArn -->
```dafny

  type AwsKmsArn = arn: AwsArn
  | AwsKmsArn?(arn)
  witness *

```

The left hand side (LHS) `type AwsKmsArn`
tells Dafny we want to define a type named `AwsKmsArn`.

`arn: AwsArn` means that base type is `AwsArn`.
To define the correctness of this `AwsArn`
we have also defined an instance that we can use.

`| AwsKmsArn?(arn)` means that this instance `arn`
MUST return `true` when passed to `AwsKmsArn?`.
The `|` can be read as "such that".

Instead of a `predicate`
Dafny will let us use any expression.
So we could have inlined `AwsKmsArn?`.
But it is simpler to prove
that a given base type satisfies a subset types constraint
when that constraint is wrapped up in a single `predicate`.

What is a `witness` clause?
In Dafny, types are generally expected to have some value.
The `witness` is there to prove to Dafny
that a value of this subset type can indeed exists.
You can imagine that this could be valuable
in the case of a complicated condition.
But since in any event Dafny will REQUIRE
that we prove any given value is correct,
in our case we don't need this.

From this you can understand that `witness *`
tells Dafny, "Don't worry, it doesn't matter
whether a value of this type actually exists."

Dafny also has features
where you can ask for a value of a given type.
In these complicated cases
Dafny may need help to understand how to create such a value.
And the witness gives Dafny this information.
Feel free to check out the [witness clauses](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-witness)
for more details.

In the meantime,
let's create a subset type for `AwsKmsResource`

<!-- !test check AwsKmsResource -->
```dafny

  type AwsKmsResource = resource: AwsResource
  | AwsKmsResource?(resource)
  witness *

```

## Step 8

Ok! Let's get started.
Again, we just start with the signatures.

```dafny

  function ParseAwsKmsRawResources(identifier: string)
    : (result: AwsKmsResource)
  function ParseAwsKmsResources(identifier: string)
    : (result: AwsKmsResource)

```

`function` is mostly what you expect.
However, `function`s in Dafny are more restrictive
than you are probably used to.
They are syntactic sugar for expressions.
They are more like mathematical functions,
they are 1000% deterministic.
The can't mutate, or use loops, or create objects on the heap.
These restrictions are important
because `function` are the building blocks for proof.

For our purposes today they provide a good introduction.
We won't run into these restrictions for what we want to do today.
I hope that the arguments are equally clear :)

`: (result: AwsKmsResource)`?
The first `:` tells Dafny "This is the return value".
By putting it in `()` we can give our return value a name.
e.g. `result` and a type for this return value.
This lets us reference it in a postcondition or `ensures` clause.
These are things that MUST be true about the result of the function.
We could have `: AwsKmsResource`.
But for reasons beyond the scope of this workshop
the other is often preferred.

## Step 9

Here is a naive first attempt.
I'll note that it is `':'` not `":"`.
The first is a character, the second is a string.

```dafny

  function ParseAwsKmsArn(identifier: string)
    : (result: AwsKmsArn)
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

    arn
  }

```

Now we see 2 problems.
`index out of range` and
`value does not satisfy the subset constraints of 'AwsKmsArn'`

Dafny does not believe us that `6 == |components|`.
That is, that there are at least 5 `:` in `identifier`.

This makes sense to us.
We know nothing about `identifier` that has been given to us.

How can we ask Dafny about such things?
`assert` is how Dafny will tell you what it believes to be true.
Most languages have a way for you to do "console log debugging"
where you make changes, run the code, and check the output.
`assert` is a way to do something similar.
However, instead of checking specific value
Dafny will check them all for you.

Generally `Split` functions will return a single element
if the character does not appear in the string.
So `Split("no colon", ':') == ["no colon"]`.

We can try `assert Split("no colon", ':') == ["no colon"];`
Dafny will indeed tell us that this is true!

This means we can `assert 1 <= |components|;`
and sure enough Dafny will believe us.
But any larger number, say `assert 2 <= |components|;`
Dafny will disagree.

<details><summary>Aside</summary>
<p>
Note: Some clever among you may try
`assert Split("a:b", ':') == ["a", "b"];`.
Dafny will not unwind every possible fact.
This is why I say that Dafny does not believe us.
These kinds of verification errors are not saying "This is false",
it is saying "I can't prove that *is* true".

In fact we can convince Dafny by adding
`assert Split("a:b", ':')[0] == "a";`.
</p>
</details>

## Step 10

Ok, so what do we do if there are not enough `:` in `identifier`?
Dafny does not have a ability to `throw`.
The return type in Dafny is a contract or postcondition.
That means that we MUST return an `AwsKmsArn`.

What we need is a way to express failure.
Dafny has a way to do this,
you can read about [failure compatible types here](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-update-failure)
if you like.
But we will go over everything you need here.

First we need a type that can express
the difference between `Success` and `Failure`.
In the `Wrappers` the `Result` type does exactly this.
It takes 2 type parameters.
One for the `Success` and the other for `Failure`[^monad]

[^monad]: If this sounds to you like a monad,
    then congratulations it is pretty close.
    If you have no idea what a monad is,
    then congratulations you are one of the lucky 10,000!

Update our function like so:
```dafny

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

```

`Success` is a constructor of the `datatype` `Result`.
Dafny knows that the constructor is unambiguous.
so you don't have to fully qualify it `Result.Success(arn)`.

Looking at our specification
we see "A string with 5 ":" that delimit following 6 parts:".
This means that we need `|components| == 5`.

We could write
```dafny

  function ParseAwsKmsArn(identifier: string)
    : (result: Result<AwsKmsArn, string>)
  {

    var components := Split(identifier, ':');

    if |components| != 6 then
      Failure("Malformed arn: " + identifier)
    else

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

```

This is great!
Dafny now believes us that `components[5]` will _always_ be valid.
You can even ask Dafny `assert |components| < 7;` and it will object.
But pretty quickly we are going to introduce a pyramid of doom
as we continually indent for more and more each such condition.

## Step 11

But `Wrappers` has us covered.
In addition to giving us the `Result` type,
it gives us a `Need` function that will
nicely abstract the above code for us.

Instead we will use

```dafny

  function ParseAwsKmsArn(identifier: string)
    : (result: Result<AwsKmsArn, string>)
  {
    var components := Split(identifier, ':');

    :- Need(6 == |components|, "Malformed arn: " + identifier);

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

```

`:-` is the Elephant operator,
or ["Update with Failure"](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-update-failure)
It will look at the return value
and if the return has a value it will extract it,
and if it does not have a value it will halt and return the error.

In the case of `Need`,
instead of a `Result` it returns an `Outcome`.
This is just a fancy way of saying:
"This does not need to return a value".
Since there is never a value,
there is no need to have a `var`
to hold a temporary variable.

`Need` both flattens your code,
and it uses positive logic.
This way you can express
what you `Need` to be true to continue!

Now, we _could_ annotate this `Need` line with duvet.
But duvet wants both the implementation
*and* evidence that it is correct.
Dafny gives us an even more powerful too.
Stay tuned.

## Step 12

Now let's deal with
`value does not satisfy the subset constraints of 'AwsKmsArn'`.
Since we stuffed all of the constraints
of `AwsKmsArn` into a single predicate
this is all we `Need`:
`:- Need(AwsKmsResource?(resource), "Malformed resource: " + identifier);`

```dafny

  function ParseAwsKmsArn(identifier: string)
    : (result: Result<AwsKmsArn, string>)
  {
    var components := Split(identifier, ':');

    :- Need(6 == |components|, "Malformed arn: " + identifier);

    var resource := ParseAwsKmsResources(components[5]);

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

```

## Step 13

Now we have an implementation let's review it for correctness.
Our first requirement is
'A string with 5 ":" that MUST delimit following 6 parts:'.

<!-- !test check ParseAwsKmsArn Correctness -->
```dafny

  function ParseAwsKmsArn(identifier: string)
    : (result: Result<AwsKmsArn, string>)

    ensures result.Success? ==> |Split(identifier, ':')| == 6

```

1. `ensures` is how Dafny expresses a postcondition.
This means that when the `ParseAwsKmsArn` is "done"
all `ensures` clauses MUST be true.
If Dafny can not prove them it will complain.
`ensures` clause are never actually executed
so the computational overhead
of many calls to `Split` will not exist in the compiled code.

1. `.Success?`
Remember that `ParseAwsKmsArn` returns a `Result`.
A `Result` can be constructed as either
`Result.Success` or `Result.Failure`.
For all `datatype`s Dafny adds a special `predicate`
that lets you check what constructor of the `datatype`
was used.

1. `==>` is the implication operator.
It is like an `if` without an `else`.
If the condition to the left of `==>` is true,
then the condition to the right of `==>` MUST be true.

Putting all this together,
we can read this as
"`ParseAwsKmsArn` succeeding implies
that the called string was split into 6 parts"

Now, go to the `duvet` report (compliance_report.html)
and click on this requirement.
You should get a popup.
Click on the `IMPLICATION` tab
and then paste right above the `ensures` clause!

You should see an annotation
in the code that looks like this

<!-- !test check duvet requirement -->
```dafny

    //= aws-kms-key-arn.txt#2.5
    //= type=implication
    //# A string with 5 ":" that MUST delimit following 6 parts:

```

1. `//=` and `//#`
This is duvet!
This is how we take our implementation
and annotate so that we know we captured every requirement.

1. `//= type=implication`
`duvet` wants us to annotate the implementation
*and* provide some evidence that the implementation is correct.
Dafny has strong static typing.
This means that it is self evident
that this function takes one argument at that this argument is correct.
If you used `duvet` in say JavaScript,
you would want a test ensure this kind of thing.
Since in JS you can pass most anything you like...

Run `make duvet_report` and our report will have updated.
This requirement is now green!

## Step 14

Looking at our specification
we can fill in several of our requirements.
All of this syntax we have already gone over.

<!-- !test check ParseAwsKmsArn all requirement -->
```dafny

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

```

But wait!
Dafny is complaining:
The postcondition
`ensures result.Success? ==> 0 < |Split(identifier, ':')[5]|`
may not hold.

Hum, obviously we need to update `ParseAwsKmsResources`
to return a `Result`.

<!-- !test check ParseAwsKmsResources stub -->
```dafny

  function ParseAwsKmsResources(arnResource: string)
    : (result: Result<AwsKmsResource, string>)

```

Whoops, now we also have to update our call.
Since we return a `Result` now.

```dafny

    var resource :- ParseAwsKmsResources(components[5]);

```

Let's think about this.
`ParseAwsKmsResources` does not have any `ensures` on it.
So Dafny is unable to make any connection
between the `AwsKmsResource` and the input `string`.
So let's fix that.

<!-- !test check ParseAwsKmsResources all requirements -->
```dafny

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

```

Success!!
Let's go over some cool things about this moment.

First, we have added constraints to a method *before* implementing it.
We talked before about how Dafny
was ok without having a body.
Now we show that Dafny will honor
requirements on these stubs.
Since Dafny will also force us
to `ensure` these requirements in our implementation
this kind of specification driven development
is a powerful tool in our toolbox.

Second, we have added two requirements
to a single single `duvet` annotation.
This works because these requirements are contiguous.

Finally, take a look at the "non-empty" requirement
and see if you can work out why this is indeed enforced.

## Step 15

Now we can add an implementation to `ParseAwsKmsResources`.

<!-- !test check ParseAwsKmsResources full -->
```dafny

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

```

1. `info[1..]`
This is a slice notation.
This will return a new sequence.
It will include the second element.
If you want more details see [here](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-other-sequence-expressions)


## Step 16

Again looking at our specification
we need to handle an AWS KMS identifier.
This is covered in sections 2.8 and 2.9.
This adds some complexity.
Since a raw key id is not a complete resource section.

So let's throw up the last of our implementation as stubs

<!-- !test check Identifier stubs -->
```dafny

  datatype AwsKmsIdentifier =
    | AwsKmsArnIdentifier(a: AwsKmsArn)
    | AwsKmsRawResourceIdentifier(r: AwsKmsResource)

  function ParseAwsKmsIdentifier(identifier: string)
    : (result: Result<AwsKmsIdentifier, string>)

  function ParseAwsKmsRawResources(identifier: string)
    : (result: Result<AwsKmsResource, string>)

  //= aws-kms-key-arn.txt#2.9
  //= type=implication
  //# This function MUST take a single AWS KMS identifier
  predicate MultiRegionAwsKmsIdentifier?(identifier: AwsKmsIdentifier)

  //= aws-kms-key-arn.txt#2.8
  //= type=implication
  //# This function MUST take a single AWS KMS ARN
  //# If the input is an invalid AWS KMS ARN this function MUST error.
  predicate MultiRegionAwsKmsArn?(arn: AwsKmsArn)

  predicate MultiRegionAwsKmsResource?(resource: AwsKmsResource)

```

What is going on here?!

As promised we have a `datatype` with multiple constructors.
You can see that we reference the type here `: (result: Result<AwsKmsIdentifier, string>)`.
In that function we will need to create
either a `AwsKmsArnIdentifier(a)` or a `AwsKmsRawResourceIdentifier(r)`.
This is how you define a "Discriminated Union" in Dafny.
That's just a fancy way of saying "An A or a B" :)

## Step 17

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
      var r :- ParseAwsKmsRawResources(identifier);
      Success(AwsKmsRawResourceIdentifier(r))
  }

```

Since Dafny treats `string` as a sequence characters
`<=` means "start with".
This is probably a little surprising.
But the only way for 2 sequences to be equal
is if they are the same length
and every element is the same in the same order.
This bounds the "greater than" to adding any number of elements.

We also have `:-` with value returning types.
Feel free to replace that with assignment (`:=`)
and see what happens.
Finally, you can see that we create `AwsKmsIdentifier`.
Dafny is smart enough to know that
`AwsKmsArnIdentifier` and `AwsKmsRawResourceIdentifier`
are unique tokens.
So you don't need to fully qualify them
like this `AwsKmsIdentifier.AwsKmsArnIdentifier(a)`

Again, notice that Dafny is OK with us calling our stub.
This is a powerful tool.
Dafny will uses these requirements
and then when an implementation is added make sure they are honored.

## Step 18

Lets do `ParseAwsKmsRawResources`.
First we will do a quick naive implementation.

```dafny

  function ParseAwsKmsRawResources(identifier: string)
    : (result: Result<AwsKmsResource, string>)
  {
    if "alias/" <= identifier then
      ParseAwsKmsResources(identifier)
    else
      :- Need(!("key/" <= identifier), "Malformed raw key id: " + identifier);
      var resource := AwsResource(
        resourceType := "key",
        value := identifier
      );

      Success(resource)
  }

```

Hum, so Dafny does not believe us.
Let's see,
does it believe `assert resource.resourceType == "key";`?

Hum, so what is the other condition then?
`assert 0 < |resource.value|;`

Yup! Oh, right, if `identifier == "key\"`
then `0 == |resource.value|`!
Fun fact Dafny lets you express this kind of implication
like this `identifier == "key\" ==> 0 == |resource.value|`.
We will use the implication operator `==>` a lot in a bit.

Now we could use `ParseAwsKmsResources`
but that has a bunch of redundant string operations.
Let's just add the condition to our exising `Need`:

<!-- !test check ParseAwsKmsRawResources complete -->
```dafny

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

```

## Step 19
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

```

The most interesting thing here
is that we are doing what looks like a recursive call
in our `ensures` clause.
This is not actually recursive.
This is because we did not give our `predicate` a named result.
This is just telling Dafny what to expect about the result.

Now `MultiRegionAwsKmsResource?`.

This is always a `key` that starts with `mrk-`.
Given everything we have learned we have learned:

<!-- !test check MultiRegionAwsKmsResource? -->
```dafny

  predicate MultiRegionAwsKmsResource?(resource: AwsKmsResource)
  {
    && resource.resourceType == "key"
    && "mrk-" <= resource.value
  }

```

Finally `MultiRegionAwsKmsIdentifier?`!!

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

The `match` expression.
This looks at they possible constructors of `AwsKmsIdentifier`
and creates a branch for each one.
If say `AwsKmsArnIdentifier` had more arguments,
then we would be required to list them all.
These arguments the bind variables that are in scope
in that `case` branch.

## Step 20

Wait!
Run `make duvet_report`.
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
Dafny expresses this with the keyword `requires`

<!-- !test check MultiRegionAwsKmsIdentifier?Correct with requires -->
```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(identifier: string)
    requires ParseAwsKmsIdentifier(identifier).Success?

```

Now everywhere we can assume that the string `s`
is a valid `AwsKmsIdentifier`!
This simplifies our first requirement

<!-- !test check MultiRegionAwsKmsIdentifier?Correct first ensures -->
```dafny

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

```

## Step 27

TODO run duvet with a CI so that we can see the exit code.
