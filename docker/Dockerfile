# Use NixOS/nix as the base image
FROM nixos/nix

# Set the working directory in the container
WORKDIR /usr/src/app

# For better cashing, first copy only files that maybe required
# for building nix environment.
COPY *.nix manifests patch script .

# Install the Fuel tools using Nix
RUN nix-channel --add https://nixos.org/channels/nixos-unstable nixos \
    && nix-channel --update \
    && nix --extra-experimental-features "nix-command flakes" build github:FuelLabs/fuel.nix#fuel
# Correct URL to repository is : https://github.com/FuelLabs/fuel.nix/

# Now, once we finished long, expensive nix building, we can
# copy over all contents of the current directory into the container at /usr/src/app 
COPY . .

# Define environment variable for Nix
ENV ENV="/root/.nix-profile/etc/profile.d/nix.sh"

# Run a shell when the container launches
CMD ["/bin/bash"]

