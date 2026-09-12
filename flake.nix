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

          nativeBuildInputs = [
            pkgs.zola
            pkgs.cacert
          ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild
            export HOME="$TMPDIR"
            # Zola's load_data() builds an HTTP client even for local files,
            # and the sandbox has no system CA bundle — point it at cacert.
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
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
