{
  description = "A Nix-flake-based Java development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

  outputs =
    { self, nixpkgs }:
    let
      javaVersion = 21; # Change this value to update the whole stack
      overlays = [
        (final: prev: rec {
          jdk = prev."jdk${toString javaVersion}";
          gradle = prev.gradle.override { java = jdk; };
          maven = prev.maven.override { inherit jdk; };
        })
      ];
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit overlays system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          libs = with pkgs; [
            libpulseaudio
            libGL
            glfw
            openal
            stdenv.cc.cc.lib
          ];
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gradle
              jdk
            ];
            buildInputs = libs;
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
          };
        }
      );
    };
}
