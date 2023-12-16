{
  inputs.nixpkgs.url = "github:nrdxp/nixpkgs/init-rot";
  inputs.organist.url = "github:nrdxp/organist/direnv-watch";

  nixConfig = {
    extra-substituters = ["https://organist.cachix.org"];
    extra-trusted-public-keys = ["organist.cachix.org-1:GB9gOx3rbGl7YEh6DwOscD1+E/Gc5ZCnzqwObNH2Faw="];
  };

  outputs = {organist, ...} @ inputs:
    organist.flake.outputsFromNickel ./. inputs {};
}
