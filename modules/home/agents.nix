{
  hermes-agent,
  lib,
  pkgs,
  config,
  ...
}:
let
  hermesPackage = hermes-agent.packages.${pkgs.system}.default;

  agentsUpdate = pkgs.writeShellApplication {
    name = "agents-update";
    runtimeInputs = with pkgs; [
      coreutils
      git
      jq
      rsync
    ];
    text = ''
      lock_file="''${1:-$HOME/.agents/.skill-lock.json}"
      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/agent-skills"
      skills_dir="''${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"

      if [ ! -f "$lock_file" ]; then
        echo "missing lock file: $lock_file" >&2
        exit 1
      fi

      mkdir -p "$cache_dir" "$skills_dir"

      jq -r '.skills | to_entries[] | [.key, .value.sourceUrl, .value.skillPath] | @tsv' "$lock_file" |
        while IFS="$(printf '\t')" read -r name source_url skill_path; do
          if [ -z "$source_url" ] || [ -z "$skill_path" ]; then
            echo "skip $name: missing sourceUrl or skillPath" >&2
            continue
          fi

          repo_hash="$(printf '%s' "$source_url" | sha256sum | cut -d ' ' -f 1)"
          repo_dir="$cache_dir/$repo_hash"

          if [ -d "$repo_dir/.git" ]; then
            git -C "$repo_dir" pull --ff-only
          else
            git clone --depth 1 "$source_url" "$repo_dir"
          fi

          skill_dir="$repo_dir/''${skill_path%/SKILL.md}"
          if [ ! -f "$skill_dir/SKILL.md" ]; then
            echo "skip $name: missing $skill_path in $source_url" >&2
            continue
          fi

          tmp_dir="$skills_dir/.$name.tmp"
          skill_dest="$skills_dir/$name"
          rm -rf "''${tmp_dir:?}"
          mkdir -p "$tmp_dir"
          rsync -a --delete "$skill_dir"/ "$tmp_dir"/
          rm -rf "''${skill_dest:?}"
          mv "$tmp_dir" "$skill_dest"
      echo "updated $name"
        done
    '';
  };
in
{
  options.dotfiles.agents.hermes.enable = lib.mkEnableOption "Hermes agent package and config";

  config = {
    home.packages = [
      agentsUpdate
    ]
    ++ lib.optional config.dotfiles.agents.hermes.enable hermesPackage;

    home.file.".agents/.skill-lock.json".source = ../../files/home/.agents/.skill-lock.json;
    home.file.".hermes/config.yaml" = lib.mkIf config.dotfiles.agents.hermes.enable {
      source = ../../files/home/.hermes/config.yaml;
    };

    home.file.".codex/config.toml".source = ../../files/home/.codex/config.toml;
    home.file.".codex/rules/default.rules".source = ../../files/home/.codex/rules/default.rules;
  };
}
