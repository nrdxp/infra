let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  direnv.watch_files = [".rot-keys", "rot.jsonnet"],
  shells = organist.shells.Bash,

  shells.dev = {
    packages =
      std.array.map
        (fun pkg => { field = pkg, value = organist.import_nix "nixpkgs#%{pkg}" })
        ["opentofu", "rot", "gopass"]
      |> std.record.from_array,
    packages.terragrunt = organist.import_nix "self#terragrunt",
    hooks.secrets = m%"
    if gpg --card-status &>/dev/null; then
      if ! diff -q <(gopass cat "$KEYS_PATH") .rot-keys; then
        if [[ -r .rot-keys ]]; then
          >&2 echo "Syncing rot keys"
          gopass fscopy .rot-keys "$KEYS_PATH"
        else
          >&2 echo "Setting up rot keys"
          gopass fscopy "$KEYS_PATH" .rot-keys
        fi
      fi
    fi
  "%,
  }
}
  | (
    organist.OrganistExpression
    & organist.tools.direnv.Schema
  )
