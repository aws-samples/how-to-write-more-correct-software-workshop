FROM gitpod/workspace-full:2022-05-08-14-31-53

# Install .NET Runtime
RUN sudo apt-get update && \
  sudo apt-get install -y aspnetcore-runtime-6.0

# Install Dafny
RUN curl https://github.com/dafny-lang/dafny/releases/download/v3.9.0/dafny-3.9.0-x64-ubuntu-16.04.zip -L -o ~/dafny.zip
RUN unzip -qq -d ~ ~/dafny.zip && rm ~/dafny.zip
RUN echo 'export PATH="${HOME}/dafny:$PATH"' >> $HOME/.bashrc

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Install Duvet
# TODO: Could this be cleaner? 
# https://stackoverflow.com/questions/49676490/when-installing-rust-toolchain-in-docker-bash-source-command-doesnt-work
# suggests using ENV instead to pick up the new path,
# but that's not the environment the VS Code process will give you in a terminal
RUN ${HOME}/.cargo/bin/cargo +stable install duvet
