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
                server-watch = pkgs.writeShellScriptBin "server_watch" ''
                  watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "gleam run"
                '';

                client-watch = pkgs.writeShellScriptBin "client_watch" ''
                  watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "gleam run -m lustre/dev build --outdir=../server/priv/static --detect-tailwind=false"
                '';

                styles-watch = pkgs.writeShellScriptBin "styles_watch" ''
                  tailwindcss -i ./src/client.css -o ./priv/static/client.css --watch
                '';

                db-cli = pkgs.writeShellScriptBin "db_cli" ''
                  docker exec -it shopping_db bash -c "psql -U postgres -d shopping"
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
                    inotify-tools

                    server-watch
                    client-watch
                    styles-watch
                    db-cli
                  ];
                };

            shellHook = ''
              echo "🚀 Development shell ready."
              echo "Use 'server_watch' to reload the server."
              echo "Use 'styles_watch' to reload the css."
              echo "Use 'db_cli' to enter into the db."
            '';
          };
        })
  );
}
