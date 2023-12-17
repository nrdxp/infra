let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

{
  direnv.watch_files = [".rot-keys", "rot.jsonnet"],
  shells = organist.shells.Bash,

  shells.dev = {
    packages =
      std.array.map
        (fun pkg => { field = pkg, value = organist.import_nix "nixpkgs#%{pkg}" })
        ["terragrunt", "opentofu", "rot", "gopass"]
      |> std.record.from_array,
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
      if gopass ls "$PASS_PATH" &>/dev/null; then
        set -a
        . <(gopass cat "$PASS_PATH" | rot run printenv | grep -E "$(rot show-config | rot jq -r '.values | keys[]' | head -c -1 | tr '\n' '|')")
        set +a
      fi
    fi
  "%,
  }
}
  | (
    organist.OrganistExpression
    & organist.tools.direnv.Schema
  )
