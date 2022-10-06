
# Workshop Environment Alternatives

These instructions are provided as a backup if you are not able to use our provided development container.

## Codespaces

Click the badge below to open this repository in a GitHub Codespace. This is currently only available for users in the [personal account beta](https://docs.github.com/en/codespaces/overview).

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=542194938){:target="_blank"}

This is currently only available for users in the [personal account beta](https://docs.github.com/en/codespaces/overview).

## Manual setup

Of course there's always the option of installing everything you need on your own computing environment!

You will need to install the following:

1. [Dafny](https://github.com/dafny-lang/dafny/wiki/INSTALL)
    1. Make sure that the `dafny` CLI is on your PATH.
    1. The workshop involves compiling Dafny code to multiple target programming languages,
       so be sure to follow the instructions on 
       [installing these languages](https://github.com/dafny-lang/dafny/wiki/INSTALL#compiling-dafny) as well.
2. [Duvet](https://github.com/awslabs/duvet)
    1. First install [Rust](https://www.rust-lang.org/tools/install)
    2. Then run `cargo +stable install duvet`
3. [Visual Studio Code](https://code.visualstudio.com/download), plus some necessary extensions:
    1. [Dafny](https://marketplace.visualstudio.com/items?itemName=dafny-lang.ide-vscode)
    2. [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)
