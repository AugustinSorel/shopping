{
  description = "My gleam application";


  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-gleam.url = "github:arnarg/nix-gleam";
  };

  outputs = { self, nixpkgs, flake-utils, nix-gleam, }: (
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              nix-gleam.overlays.default
            ];
          };
        in
        {
          packages = {
            default = pkgs.buildGleamApplication {
              src = ./.;
            };
          };

          devShells = {
            default =
              let
                styles-watch = pkgs.writeShellScriptBin "styles_watch" ''
                  tailwindcss -i ./src/styles/styles.css -o ./priv/static/styles.css --watch
                '';

                db-cli = pkgs.writeShellScriptBin "db_cli" ''
                  docker exec -it shopping_plo_plo_db bash -c "psql -U postgres -d shopping_plo_plo"
                '';
              in

              pkgs.mkShell
                {
                  buildInputs = with pkgs;[
                    gleam
                    erlang_28
                    elixir
                    beamMinimal27Packages.rebar3
                    tailwindcss_4
                    watchman
                    goose
                    watchexec

                    styles-watch
                    db-cli
                  ];
                };
          };
        })
  );
}
