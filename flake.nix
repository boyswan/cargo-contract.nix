{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, crane, nixpkgs, flake-utils, fenix, ... }:  
    let
      system = "aarch64-darwin";  
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ fenix.overlays.default ];
      };

      rust-toolchain = with pkgs.fenix; combine [
        pkgs.fenix.latest.toolchain
        targets.wasm32-unknown-unknown.stable.rust-std
      ];

      src = pkgs.fetchFromGitHub {
        owner = "paritytech";
        repo = "cargo-contract";
        rev = "0d7cf47647c5e759c43388823a3505adac455be7";
        sha256 = "sha256-TcIqpMVowbs5cUp53OCr6bH4yv4YpEOmMfBVOYKojgg=";
      };

      craneLib = crane.lib.${system}.overrideToolchain rust-toolchain; 

      cargo-contract = craneLib.buildPackage {
        pname = "cargo-contract";
        version = "3.0.1";
        src = src;
        doCheck = false;

        buildInputs = with pkgs; [
          pkg-config
          cmake
          libiconv
          darwin.apple_sdk.frameworks.Security
        ];
      };

  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        rust-toolchain
        cargo-contract
        pkg-config
        cmake
        libiconv
        darwin.apple_sdk.frameworks.Security
      ];
    };
  };
}
