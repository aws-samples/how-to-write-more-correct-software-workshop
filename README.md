# How To Write More Correct Software

Welcome to the How To Write More Correct Software workshop!

We're here to help you learn how to use two powerful tools
to make more of your code more correct:

1. [Dafny](dafny.org), a programming language that formally verifies your implementation matches your specification
2. [Duvet](https://github.com/awslabs/duvet), a code quality tool for measuring how well your human-readable specification is covered in code

This content is currently a work in progress - use at your own risk, mind our dust, and stay tuned!

## Getting Started

This workshop is best experienced though Visual Studio Code (VS Code) on a sandboxed, pre-built development container.
There are currently three different options, listed from most to least preferred below.

Once you have your environment, open up [the instructions](./instructions/steps.md) and you're off!

### Codespaces

Click this badge to open this repository in a GitHub Codespace:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=542194938)

This is currently only available for users in the [personal account beta](https://docs.github.com/en/codespaces/overview).

### GitPod

Click this button to open this repository in a GitPod workspace:

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/aws-samples/how-to-write-more-correct-software-workshop) 

If you are not already signed in as a GitHub user,
you will be prompted to authenticate through GitHub.

### Manual setup

You will need to install the following:

1. [Dafny](https://github.com/dafny-lang/dafny/wiki/INSTALL)
    1. Make sure that the `dafny` CLI is on your PATH.
    1. The workshop involves compiling Dafny code to multiple target programming languages,
       so be sure to follow the instructions on 
       [installing these languages](https://github.com/dafny-lang/dafny/wiki/INSTALL#compiling-dafny) as well.
2. [Duvet](https://github.com/awslabs/duvet)
    1. First install [Rust](https://www.rust-lang.org/tools/install)
    2. Then run `cargo +stable install duvet`)
3. [Visual Studio Code](https://code.visualstudio.com/download), plus some necessary extensions:
    1. [Dafny](https://marketplace.visualstudio.com/items?itemName=dafny-lang.ide-vscode)
    2. [Live Server](https://marketplace.visualstudio.com/items?itemName=dafny-lang.ide-vscode)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License Summary

The documentation is made available under the Creative Commons Attribution-ShareAlike 4.0 International License. See the LICENSE file.

The sample code within this documentation is made available under the MIT-0 license. See the LICENSE-SAMPLECODE file.
