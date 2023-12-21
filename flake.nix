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
          terragrunt = pkgs.writeShellScriptBin "terragrunt" ''
            terragrunt="${pkgs.terragrunt}/bin/terragrunt"
            if gpg --card-status &>/dev/null && [[ -v PASS_PATH ]]; then
              gopass cat "$PASS_PATH" | rot run "$terragrunt" "$@"
            else
              "$terragrunt" "$@"
            fi
          '';
        };
      }
    ));
}
