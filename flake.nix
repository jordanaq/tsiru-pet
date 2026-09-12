{
  description = "tsiru.pet — personal site (Zola)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # `nix build` here produces a store path containing the built site —
      # exactly what the cloud-server flake consumes as a flake input.
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "tsiru-pet-site";
          version = "0.1.0";

          src = self;

          nativeBuildInputs = [ pkgs.zola ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild
            export HOME="$TMPDIR"
            zola build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r public/. $out/
            runHook postInstall
          '';

          meta = {
            description = "Static build of the tsiru.pet personal site";
            homepage = "https://tsiru.pet";
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.zola
            pkgs.jq
            pkgs.curl
          ];
        };
      });
    };
}
