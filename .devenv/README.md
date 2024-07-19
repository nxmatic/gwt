# GWT Development Environment

This repository provides a development environment for the Google Web Toolkit (GWT) using Nix flakes. It sets up the necessary tools and dependencies to build and develop GWT applications efficiently.

## Features

- **JDK 17**: The development environment includes JDK 17 for Java development.

- **Apache Ant**: Build tool for automating software build processes.

- **Maven**: Dependency management and project management tool for Java projects.

- **GWT Tools**: Includes GWT-specific tools for building and running GWT applications.

## Getting Started

### Prerequisites

- Ensure you have [Nix](https://nixos.org/download.html) installed on your system.
- Enable flakes support by adding the following line to your Nix configuration:

  ```bash
  experimental-features = nix-command flakes
  ```

## Usage

### Enter the Development Shell

To enter the development shell with all necessary dependencies, run:

  ```bash
  nix develop
  ```

### Build the GWT Application:
You can package your GWT application using the provided build script:

  ```bash
  nix run .devenv#build-gwt
  ```

### Environment Variables

- `GWT_VERSION`: Set this environment variable to specify a custom GWT version.
- `GWT_TOOLS`: This variable points to the GWT tools used in the environment.

### Directory Structure

- `flake.nix`: The main Nix flake file that defines the development environment and packages.
- `compute-gwt-version.sh`: A script to compute the current GWT version based on the project files.
- `gwt-packages/flake.nix`: The flake file that defines the packages.
- `gwt-packages/gwt.nix`: The derivation for the GWT package.
- `gwt-packages/gwtTools.nix`: The derivation for the GWT tools package.

## Contributing

Contributions are welcome! If you have suggestions or improvements, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Thanks to the Nix community for their support and resources.
Special thanks to the GWT community for providing the tools and documentation that make this project possible.
