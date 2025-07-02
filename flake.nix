{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system} = {
        default =
          let
            server-watch = pkgs.writeShellScriptBin "server_watch" ''
              templ generate --watch --proxy="http://localhost:8080" --cmd="go run ./cmd/api/main.go"
            '';

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

                server-watch
                styles-watch
                db-cli
              ];
            };
      };
    };
}
