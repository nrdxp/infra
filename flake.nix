{
  inputs.nixpkgs.url = "github:nrdxp/nixpkgs/init-rot";
  inputs.organist.url = "github:nrdxp/organist/direnv-watch";
  inputs.nosys.url = "github:divnix/nosys";

  nixConfig = {
    extra-substituters = ["https://organist.cachix.org"];
    extra-trusted-public-keys = ["organist.cachix.org-1:GB9gOx3rbGl7YEh6DwOscD1+E/Gc5ZCnzqwObNH2Faw="];
  };

  outputs = {
    organist,
    nosys,
    ...
  } @ inputs:
    organist.flake.outputsFromNickel ./. inputs {}
    // (nosys inputs (
      {nixpkgs, ...}: let
        inherit (nixpkgs.legacyPackages) pkgs;
      in {
        packages = {
          terragrunt = let
            inner = pkgs.writeShellScript "inner" ''
              export SPACES_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
              export SPACES_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
              "$terragrunt" "$@"
            '';
          in pkgs.writeShellScriptBin "terragrunt" ''
            export terragrunt="${pkgs.terragrunt}/bin/terragrunt"
            if gpg --card-status &>/dev/null; then
              gopass cat "$PASS_PATH" | rot run "${inner}" "$@"
            else
              "$terragrunt" "$@"
            fi
          '';
        };
      }
    ));
}
