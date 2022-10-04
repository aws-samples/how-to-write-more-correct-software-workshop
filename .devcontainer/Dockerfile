# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.245.2/containers/codespaces-linux/.devcontainer/base.Dockerfile

FROM mcr.microsoft.com/vscode/devcontainers/universal:2-focal

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive

USER codespace

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# TODO: Could this be cleaner? 
# https://stackoverflow.com/questions/49676490/when-installing-rust-toolchain-in-docker-bash-source-command-doesnt-work
# suggests using ENV instead to pick up the new path,
# but that's not the environment the VS Code process will give you in a terminal
RUN /home/codespace/.cargo/bin/cargo +stable install duvet
