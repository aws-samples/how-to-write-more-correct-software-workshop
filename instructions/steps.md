
## Step 1

First open the `exercises/start` directory in VSCode.
Now open the file `AwsKmsArnParsing.dfy`.
Most of the things here should make sense,
but lets go over them all.

`include` is how Dafny includes other files.
The file `include.dfy` is a helper file we added for you.
It has a few things things to help you.

`module`, also pretty simple.
This is how Dafny organizes code.
This `module` is called `AwsKmsArnParsing`.
Everything in `{}` is the contents of the `module`.
Dafny does have ways to control what gets exported,
but for now, lets just say "everything is exported.

`import` takes a named module
and bring it into scope in an existing module.
`opened` takes all the exported names
in the imported module and puts them in the current namespace.
This is where we will get symbols that don't exist in this file.
For example `Split` and `Join`.

Ok, so what about `{:options "-functionSyntax:4"}`?
This is to simplify upgrading.
When Dafny v4 comes out modules with this option
will "Just Work".
You don't need to work about this for the workshop,
but if you are *really* interested:
see [Controlling language features
](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-controlling-language) for more details.

## Step 2

### TODO change this to run duvet here and then open that spec

Since we are dealing with correct software,
we need a definition of correctness!
So open the specification `aws-kms-key-arn.txt`.

Go ahead and and look through the doc.
We will take you through the sections as we do the workshop,
but its nice to get some of it in your head.

## Step 3

We need some parts.
Since we are going to be parsing strings
we need some containers to put the parts of the strings in.

Also, we need to say how these containers are correct.

Paste into the module the following code
and then we will go over what it means

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
In this case we only have one.
Later we will have more.

What is a `predicate` and whats the deal with that`?` at the end?
A `predicate` is just a function that returns a `boolean`.
It is just sugar for `function AwsArn?(arn:AwsArn) : bool`.

Generally such functions ask a question.
For example "Is this AwsArn `arn` a valid AwsArn?".
Since `?` is a perfectly good character for a name in Dafny,
it is often added to a `predicate`.
This also nicely binds the intention `predicate` with the `datatype`.

Finally, you will notice that Dafny perfectly happy
with not havening any details or implementation.
We will use this later.

## Step 4

Let's add some properties to our `datatype`'s.

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
This means is `obj` is an `AwsArn` then `obj.service` is a `string`.
But what about `nameonly`?

Positional arguments are nice and compact.
At the definition, what the names are is obvious.
However, at the call site you might wonder:
What is the 3rd parameter again?

`nameonly` forces callers to use named parameters.
This makes the call site more verbose.
But it makes it much more readable for future you,
or anyone new to the codebase.

You are not required to use it.
But I highly recommend it.

## Step 5

Now we have some containers,
lets talk about what values are correct for these containers to hold.

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

A `predicate` is a kind of function.
Functions in Dafny are just syntactic sugar for expressions.
You will note that there is no `;`.
The return value for any `predicate` or `function`
is just the vary last unterminated expression.

The leading `&&` is just sugar.
Allowing leading boolean operators like this
lets you reorder things nicely.
It may look strange at first,
but leading tokens like this grow on you.

`|arn.partition|`?
`string`'s in Dafny are a sequence of characters.
Surrounding a sequence with `|` will return the cardinality of a sequence.
This is just a fancy way of saying "length".
So `0 < arn.partition.length`
is probably how you would expect that to be written
in a language you are more familiar with.

I will also note that we are calling `AwsResource?`
even though it does not have an implementation.
If you tried to compile this
Dafny would complain.
But all Dafny needs for `AwsArn?` to be valid
is to be able to prove that it will always return a `bool`.
Feel free to change `AwsResource?` to a function
that returns something else and see :)
`function AwsResource?(resource: AwsResource): string`

So we can read this as:
The arnLiteral MUST be the string "arn"
and partition, service, region, and account
MUST NOT be empty string
and finally the resource MUST be a correct AwsResource.

## Step 6

Using what we have learned
let's give our remaining three `predicate`'s implementations.

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
Does this seem to capture most of what it says makes a valid AWS KMS ARN?

## Step 7

Many languages have types similar to Dafny's `datatype`
albeit not always immutable.
These kinds of types have a quality of correctness.
After all you can't put a number into a string...
If these kinds of types represent the basic shape of your data,
then Dafny's Subset type is a painting
full of light, shadow, and color.

A Subset type lets us combine the correctness we in
in `predicate`s with a base `datatype`.
We can then reason about this new type statically.

As we will see,
to return a subset type we will need to prove
that the `datatype` has been constructed correctly.
But after that this correctness in baked into the type.

Let's create one!

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

What is a witness?
In Dafny, types are generally expected to have some value.
The witness is there to prove to Dafny
that a value of this subset type can indeed be created.
You can imagine that this could be valuable
in the case of a complicated condition.
But since in any event Dafny will REQUIRE
that we prove any given value is correct,
in our case we don't need this.

From this you can understand that `witness *`
tells Dafny, "Don't worry, I take responsibility for creating values.

Dafny also has features
where you can ask for a value of a given type.
In these complicated cases
Dafny may need help to understand how to create such a value.
And the witness gives Dafny this information.
Feel free to check out the [witness clauses](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-witness)
for more details.

In the meantime,
let's create a subset type for `AwsKmsResource`

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

`function` is what you would expect.
I hope that the arguments are equally clear :)

`: (result: AwsKmsResource)`?
The first `:` tells Dafny "This is the return value".
By putting it in `()` we can give our return value a name.
e.g. `result` and a type for this return value.
This lets us reference it in a postcondition or `ensures` clause.
These are things that MUST be true when the function ends.
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
That is that there are at least 5 `:` in `identifier`.

This makes sense to us.
We know nothing about `identifier` that has been given to us.

How can we ask Dafny about such things?
`assert` is how Dafny will tell you what it believes to be true.

Generally `Split` functions will return a single element
if the character does not appear in the string.
So `Split("no colon", ':') == ["no colon"]`.

We can try `assert Split("no colon", ':') == ["no colon"];`
Dafny will indeed tell us that this is true!

This means we can `assert 1 <= |components|;`
and sure enough Dafny will believe us.
But any larger number, say `assert 2 <= |components|;`
Dafny will agree.

Note: Some clever among you may try
`assert Split("a:b", ':') == ["a", "b"];`.
Dafny will not unwind every possible fact.
This is why I say that Dafny does not believe us.
These kinds of verification errors are not saying "This is false",
it is saying "I can't prove that *is* true".

In fact we can convince Dafny by adding
`assert Split("a:b", ':')[0] == "a";`.



## Step 10

Ok, so what do we do it there are not enough `:` in `identifier`?
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
One for the `Success` and the other for `Failure`

If this sounds to you like a monad,
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
Dafny knows that there is only 1 constructor
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
"This will never return a value".
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

    :- Need(AwsKmsArn?(arn), "Malformed resource: " + identifier);

    Success(arn)
  }

```

## Step 13

Now we can add an implementation to `ParseAwsKmsResources`.
Looking at the specification,
the resource will always have a `/`.
So we have 2 failure cases.
With everything we have learned so far

```dafny

  function ParseAwsKmsResources(identifier: string)
    : (result: Result<AwsKmsResource, string>)
  {
    var info := Split(identifier, '/');

    :- Need(1 < |info|, "Malformed resource: " + identifier);

    var resourceType := info[0];
    var value := Join(info[1..], "/");

    var resource := AwsResource(
      resourceType := resourceType,
      value := value
    );

    :- Need(AwsKmsResource?(resource), "Malformed resource: " + identifier);

    Success(resource)
  }

```

What is `info[1..]`?
This is a slice notation.
This will return a new sequence.
It will include the second element.
If you want more details see [here](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-other-sequence-expressions)

But wait!
Now there is an error back in `ParseAwsKmsArn`.
Remember we used to always return a `AwsKmsResource`.
Now we can fail.
We need to update the assignment `:=`
with the elephant `:-` to remember to fail if needed :)

`var resource := ParseAwsKmsResources(components[5]);`
goes to
`var resource :- ParseAwsKmsResources(components[5]);`

## Step 14

Again looking at our specification
we need to handle an AWS KMS identifier.
This adds some complexity.
Since a raw key id is not a complete resource section.

So let's throw up the last of our implementation as stubs

```dafny

  datatype AwsKmsIdentifier =
    | AwsKmsArnIdentifier(a: AwsKmsArn)
    | AwsKmsRawResourceIdentifier(r: AwsKmsResource)

  function ParseAwsKmsIdentifier(identifier: string)
    : (result: Result<AwsKmsIdentifier, string>)

  function ParseAwsKmsRawResources(identifier: string)
    : (result: Result<AwsKmsResource, string>)

  //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.9
  //= type=implication
  //# This function MUST take a single AWS KMS identifier
  predicate MultiRegionAwsKmsIdentifier?(identifier: AwsKmsIdentifier)

  //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.8
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
This is how you define a "Discriminant Union" in Dafny.
That's just a fancy way of saying "An A or a B" :)

What about the `//=` and `//#`?
This is duvet!
This is how we take our implementation
and annotate so that we know we captured every requirement.

And `//= type=implication`?
Well duvet wants us to annotate the implementation
*and* provide some evidence that the implementation is correct.
Dafny has strong static typing.
This means that it is self evident
that this function takes one argument at that this argument is correct.
If you used duvet in say JavaScript,
you would want a test ensure this kind of thing.
Since in JS you can pass most anything you like...

## Step 15

Let's do `ParseAwsKmsIdentifier` first.
How can we distinguish an ARN
from a resource?
Let's go with "It starts with anr:".


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
Hopefully this is somewhat intuitive.
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
We don't add any pre or post conditions in this workshop.
But if we did Dafny will uses these requirements
and then when an implementation is added make sure they are honored.

## Step 16

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

## Step 17

We are almost done with our implementation!!
Let's get done so we can prove something!

First `MultiRegionAwsKmsIdentifier?`

```dafny

  //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.9
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
These aruments the bind variables that are in scope
in that `case` branch.

Looking at the specification,
an MRK is dependent only on the resource section.
From this we can see that `MultiRegionAwsKmsArn?`
just delegates.

```dafny

  //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.8
  //= type=implication
  //# This function MUST take a single AWS KMS ARN
  //# If the input is an invalid AWS KMS ARN this function MUST error.
  predicate MultiRegionAwsKmsArn?(arn: AwsKmsArn)
  {
    MultiRegionAwsKmsResource?(arn.resource)
  }

```

Finally `MultiRegionAwsKmsResource?`!!
This is always a `key` that starts with `mrk-`.
Pretty simple with everything else we have learned.

```dafny

  predicate MultiRegionAwsKmsResource?(resource: AwsKmsResource)
  {
    && resource.resourceType == "key"
    && "mrk-" <= resource.value
  }

```

## Step 18

One way to prove things in Dafny
is with a `lemma`.
This is like a running _every_ test all at once.
In logic a lemma is like a little proof.
Something that is used on the way to prove
what you really care about.

This is how it is used in Dafny.
We want correct programs,
but sometimes we need to prove parts.

All the proof that we are going to do in this workshop
could be done directly on the `function`s.
Here we have the proof extrinsic (external)
to the `function`s.
This lets us ground some ideas as tests.
This makes for a nice mental model to start
and hopefully encourage you to prove things
about your own code.

We will start by proving that `ParseAwsKmsArn` is correct.
Start here:

```dafny

  lemma ParseAwsKmsArnCorrect(identifier: string)
  {}

```

We name the `lemma` to relate it to `ParseAwsKmsArn`.
It takes a `string`.
Because we have not placed _any_ conditions on this `string`
it represents _any_ string.
This means every length,
and every combination of characters.

So anything that this `lemma` will ensure
is like a test on every possible `string` all at once!

Look at the specification.
We will start with our first requirement
`MUST start with string "arn"`.
To be valid the string needs to start with `arn`.
We can express this as `"arn" <= identifier`.

Having a string simply start with `arn`
can not imply anything.
Since the string `"arn"` starts with `arn`!
However if `identifier` is successfully parsed,
then it MUST have started with `arn` right?

```dafny

  lemma ParseAwsKmsArnCorrect(identifier: string)
    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# MUST start with string "arn"
    ensures ParseAwsKmsArn(identifier).Success? ==> "arn" <= identifier
  {}

```

`.Success?`?
Remember that `ParseAwsKmsArn` returns a `Result`.
A `Result` can be constructed as either
`Result.Success` or `Result.Failure`.
For all `datatype`s Dafny adds a special `predicate`
that lets you check what constructor of the `datatype`
was used.

`ensures` is how Dafny expresses a postcondition.
This means that when the `lemma` is "done"
(remember lemmas are never actually executed)
all `ensures` clauses MUST be true.
If Dafny can not prove them
it will complain.

Try changing the string to something else.
Dafny will tell you "This postcondition might not hold on a return path."

It is important to note that Dafny does not say "This postcondition WILL not hold."
Dafny is very persnickety.
It will **always** start from the null hypothesis.
So while we know this is indeed false,
Dafny just says "I don't believe you".

Try negating your condition: `!("brn" <= identifier)`.
Dafny will now agree with you,
that this is true.

## Step 19

`The partition MUST be a non-empty` is our next requirement.
We dealt with non-empty before,
the cardinality is more than 0.
But here we want to tie this back to the original string.

The specification says that each part
is delimited by a `:`.
Remember that a `lemma` is never executed.
So the following: `0 < |Split(identifier, ':')[1]|`
will work nicely.

However, we know that this will only be true,
for valid `identifier`s.
We can just use the `==>` (implication) operator.

```dafny

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The partition MUST be a non-empty
    ensures ParseAwsKmsArn(identifier).Success? ==> 0 < |Split(identifier, ':')[1]|

```

In this same step,
lets look at the next few requirements.
`The service MUST be the string "kms"` is equality,
so that's just changing `<` to `==`.
The rest are just non-empty elements for each subsequent element.

```dafny

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The partition MUST be a non-empty
    ensures ParseAwsKmsArn(identifier).Success? ==> 0 < |Split(identifier, ':')[1]|

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The service MUST be the string "kms"
    ensures ParseAwsKmsArn(identifier).Success? ==> Split(identifier, ':')[2] == "kms"

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The region MUST be a non-empty string
    ensures ParseAwsKmsArn(identifier).Success? ==> 0 < |Split(identifier, ':')[3]|

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The account MUST be a non-empty string
    ensures ParseAwsKmsArn(identifier).Success? ==> 0 < |Split(identifier, ':')[4]|
    
    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The resource section MUST be non-empty
    ensures ParseAwsKmsArn(identifier).Success? ==> 0 < |Split(identifier, ':')[5]|

```

## Step 20

Let's pause here for a moment and run `duvet` again.

```
make duvet
```

When we refresh out report we can now see
that there are links to our code.

// TODO more words here

## Step 21

What is interesting here is that
our last requirement `The resource section MUST be non-empty`
has a second clause.
We could have verified all this together,
but it is better to break the requirements up.
This lowers the cognitive load.
All we need to do is look at the clause
and ask ourselves "Does this code satisfy this requirement?"

```dafny

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# and MUST be split by a
    //# single "/" any additional "/" are included in the resource id
    ensures ParseAwsKmsArn(identifier).Success? ==>
      var resource := ParseAwsKmsArn(identifier).value.resource;
      && ParseAwsKmsResources(Split(identifier, ':')[5]).Success?
      && resource == ParseAwsKmsResources(Split(identifier, ':')[5]).value
      && Split(identifier, ':')[5] == resource.resourceType + "/" + resource.value

```

Having a `var` inside of this expression may be a little surprising.
But Dafny understand that this is just a temporary variable in this expression.
Since Dafny expressions pure and immutable
as long as there is no intervening statement
there is no real difference between one expression
and any number of contiguous expressions.

In fact Dafny will also let you write the above like this
```dafny

    ensures ParseAwsKmsArn(identifier).Success? ==>
      && var resource := ParseAwsKmsArn(identifier).value.resource;
      && ParseAwsKmsResources(Split(identifier, ':')[5]).Success?
      && resource == ParseAwsKmsResources(Split(identifier, ':')[5]).value
      && Split(identifier, ':')[5] == resource.resourceType + "/" + resource.value

```

At this point,
everything else should be familiar to us except `.value`?
If you look at the definition of `Result` (in Wrappers.dfy)
it looks something like this

```dafny
datatype Result<+T, +R> =
  | Success(value: T)
  | Failure(error: R)
```

So the value in the `Success` constructor
is the "happy path" value.
If you want more information about type paramaters
you can look at [this](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-type-characteristics).
[The `+` says that T and R MUST be co-variant](https://dafny.org/dafny/DafnyRef/DafnyRef#sec-type-parameter-variance).
Variance is beyond the scope of this course :)

## Step 22

With the above we have tied the result back to the string,
From our specification we need to place constraints
on both the `resourceType` and the resource id.

This is pretty straightforward but let's
do it with a little trick just for fun.

```dafny

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The resource type MUST be either "alias" or "key"
    ensures ParseAwsKmsArn(identifier).Success? ==>
      var AwsResource(resourceType, _) := ParseAwsKmsArn(identifier).value.resource;
      "key" == resourceType || "alias" == resourceType

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.5
    //= type=implication
    //# The resource id MUST be a non-empty string
    ensures ParseAwsKmsArn(identifier).Success? ==>
      var AwsResource(_, id) := ParseAwsKmsArn(identifier).value.resource;
      0 < |id|

```

I hope this is _mostly_ what you would expect.
But let's look at `var AwsResource(resourceType, _) := ParseAwsKmsArn(identifier).value.resource;`.

If you remember the `resource` property of an `AwsArn` is an `AwsResource`.
Dafny lets us use that constructor
and pluck off the properties.
The `_` just tells Dafny, "Don't worry, I don't care about that one".

From this we can see that
`var AwsResource(_, id) := ParseAwsKmsArn(identifier).value.resource;`
is just inverting the value plucked.

I want to take a moment
and make clear what we have proved.
We have been investigating not a few strings.
Or even some strange strings.
But every possible string.
Even strings that would not fit
into your computers memory because they are too big.

We have verified that `ParseAwsKmsArn` will always honor these requirements
regardless of what string we give it.
Further, we have clearly tied each
of our documented requirements to our source.

## Step 23

Now we can do `MultiRegionAwsKmsArn?`.
Again we start out with a `lemma`

```dafny

  lemma MultiRegionAwsKmsArn?Correct(arn: AwsKmsArn)
  {}

```

You can see that it takes an `AwsKmsArn` this time.
There is nothing new in our ensures clauses
that we have not already gone over,
so lets just add them all in and take a look

```dafny

  lemma MultiRegionAwsKmsArn?Correct(arn: AwsKmsArn)
    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If resource type is "alias", this is an AWS KMS alias ARN and MUST
    //# return false.
    ensures arn.resource.resourceType == "alias" ==> !MultiRegionAwsKmsArn?(arn)
    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If resource type is "key" and resource ID starts with
    //# "mrk-", this is a AWS KMS multi-Region key ARN and MUST return true.
    ensures
      && arn.resource.resourceType == "key"
      && "mrk-" <= arn.resource.value
    ==>
      MultiRegionAwsKmsArn?(arn)
    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.8
    //= type=implication
    //# If resource type is "key" and resource ID does not start with "mrk-",
    //# this is a (single-region) AWS KMS key ARN and MUST return false.
    ensures
      && arn.resource.resourceType == "key"
      && !("mrk-" <= arn.resource.value)
    ==>
      !MultiRegionAwsKmsArn?(arn)
  {}

```

Given everything these are reasonably simple
expressions of the specifications in Dafny.

I will note that `&&` binds stronger than `==>`.
In fact, in Dafny the length of the express its strength.
This means that if you try to compose multiple `==>` together
it is best to use parentheses.
Since each `ensures` is only a single statement
I've left them out.

Let's run `duvet` again

```
make duvet
```

After we refresh the report,
we can now see more coverage in our report.
For complicated project with lots of requirements
This process helps everyone.
From this we can see that we are almost done.

## Step 24

The home stretch.
All we have left is `MultiRegionAwsKmsIdentifier?`.

We start as before with a `lemma`

```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(s: string)
  {}

```

We have started with a `string` because our requirements
are described as strings.
Incidentally this is because when you configure AWS KMS keys
they are strings.

However our `predicate` takes an `AwsKmsIdentifier`.
This means that not _every_ string is valid input.
We want to shape our input.
Instead of dealing with every possible string,
we want to deal with every string that could be a `AwsKmsIdentifier`.

This is called a precondition.
Something that MUST be true *before* the function executes.
Dafny expresses this with the keyword `requires`

```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(s: string)
    requires ParseAwsKmsIdentifier(s).Success?
  {}

```

Now everywhere we can assume that the string `s`
is a valid `AwsKmsIdentifier`!
This simplifies our first requirement

```dafny

  lemma MultiRegionAwsKmsIdentifier?Correct(s: string)
    requires ParseAwsKmsIdentifier(s).Success?

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts with "arn:", this MUST return the output of
    //# identifying an an AWS KMS multi-Region ARN (aws-kms-key-
    //# arn.md#identifying-an-an-aws-kms-multi-region-arn) called with this
    //# input.
    ensures "arn:" <= s
      ==>
        var arnIdentifier := ParseAwsKmsIdentifier(s).value;
        MultiRegionAwsKmsIdentifier?(arnIdentifier) == MultiRegionAwsKmsArn?(arnIdentifier.a)
  {}

```

Dafny uses the fact that the string `ParseAwsKmsIdentifier` will succeed
with the fact that this string starts with `arn:`
to know that `ParseAwsKmsArn` MUST succeed.
We can then wrap this `arn` so that we can compare the two calls
as the specification requires.

## Step 25

Looking at our specification,
our next two requirements are very similar.
They differ in how the string should start
and if `MultiRegionAwsKmsIdentifier?` should return true or false

```dafny

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts with "alias/", this an AWS KMS alias and
    //# not a multi-Region key id and MUST return false.
    ensures "alias/" <= s
      ==>
        var resource := ParseAwsKmsIdentifier(s).value;
        !MultiRegionAwsKmsIdentifier?(ParseAwsKmsIdentifier(s).value)

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If the input starts
    //# with "mrk-", this is a multi-Region key id and MUST return true.
    ensures "mrk-" <= s
      ==>
        var resource := ParseAwsKmsIdentifier(s).value;
        MultiRegionAwsKmsIdentifier?(resource)

```

## Step 26

Finally the specification says
"If the input does not start with any of the above,
this is not a multi-Region key id and MUST return false."
This is just a negation of the three starts with we already have.

There are a few ways to express this,
but this one mirrors the specification to make it easier
to see the correspondence.

```dafny

    //= compliance/framework/aws-kms/aws-kms-key-arn.txt#2.9
    //= type=implication
    //# If
    //# the input does not start with any of the above, this is not a multi-
    //# Region key id and MUST return false.
    ensures
        && !("arn:" <= s )
        && !("alias/" <= s )
        && !("mrk-" <= s )
      ==>
        var resource := ParseAwsKmsIdentifier(s);
        !MultiRegionAwsKmsIdentifier?(resource.value)

```

## Step 27

TODO run duvet with a CI so that we can see the exit code.
