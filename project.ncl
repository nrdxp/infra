let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  direnv.watch_files = [".rot-keys", "rot.jsonnet"],
  shells = organist.shells.Bash,

  shells.dev = {
    packages =
      std.array.map
        (fun pkg => { field = pkg, value = organist.import_nix "nixpkgs#%{pkg}" })
        ["opentofu", "rot", "gopass", "git-crypt"]
      |> std.record.from_array,
    packages.terragrunt = organist.import_nix "self#terragrunt",
    hooks.secrets = m%"
    if gpg --card-status &>/dev/null && [[ -v KEYS_PATH ]]; then
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
    if [[ -v GPG_KEY_PATH && -v GIT_CRYPT_PATH ]] && ! [[ -r "$GPG_KEY_PATH" ]]; then
      >&2 echo "Setting up git-crypt key"
      mkdir -p "$CRYPT_DIR"
      cp "$GIT_CRYPT_PATH" "$GPG_KEY_PATH"
    fi
  "%,
  }
}
  | (
    organist.OrganistExpression
    & organist.tools.direnv.Schema
  )
