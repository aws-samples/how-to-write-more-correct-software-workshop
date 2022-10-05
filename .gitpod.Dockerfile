FROM gitpod/workspace-full:2022-05-08-14-31-53

# Add the Microsoft package signing key to the list of trusted keys and add the package repository.
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#2004
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O ~/packages-microsoft-prod.deb
RUN sudo dpkg -i ~/packages-microsoft-prod.deb
RUN rm ~/packages-microsoft-prod.deb

# Install .NET Runtime
RUN sudo apt-get update && \
  sudo apt-get install -y aspnetcore-runtime-6.0

# Install Dafny
RUN curl https://github.com/dafny-lang/dafny/releases/download/v3.9.0/dafny-3.9.0-x64-ubuntu-16.04.zip -L -o ~/dafny.zip
RUN unzip -qq -d ~ ~/dafny.zip && rm ~/dafny.zip
RUN echo 'export PATH="${HOME}/dafny:$PATH"' >> $HOME/.bashrc

# Install Duvet
# TODO: Could this be cleaner? 
# https://stackoverflow.com/questions/49676490/when-installing-rust-toolchain-in-docker-bash-source-command-doesnt-work
# suggests using ENV instead to pick up the new path,
# but that's not the environment the VS Code process will give you in a terminal
RUN ${HOME}/.cargo/bin/cargo +stable install duvet
