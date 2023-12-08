# Use NixOS/nix as the base image
FROM nixos/nix

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install the Fuel tools using Nix
RUN nix-channel --add https://nixos.org/channels/nixos-unstable nixos \
    && nix-channel --update \
    && nix --extra-experimental-features "nix-command flakes" build github:FuelLabs/fuel.nix#fuel
# Correct URL to repository is : https://github.com/FuelLabs/fuel.nix/

# Define environment variable for Nix
ENV ENV="/root/.nix-profile/etc/profile.d/nix.sh"

# Run a shell when the container launches
# CMD ["/bin/sh"]
CMD ["/bin/bash"]
