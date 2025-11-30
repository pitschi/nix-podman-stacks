{
  config,
  lib,
  ...
}: let
  name = "free-games-claimer";
  cfg = config.nps.stacks.${name};
  storage = "${config.nps.storageBaseDir}/${name}";

  category = "General";
  description = "Claim Free Games";
  displayName = "Free Games Claimer";
in {
  imports = import ../mkAliases.nix config lib name [name];

  options.nps.stacks.${name} = {
    enable = lib.mkEnableOption name;
    extraEnv = lib.mkOption {
      type = (import ../types.nix lib).extraEnv;
      default = {};
      description = ''
        Extra environment variables to set for the container.

        See <https://github.com/vogler/free-games-claimer?tab=readme-ov-file#configuration--options>
      '';
      example = {
        EG_EMAIL = "first.last@example.com";
        EG_PASSWORD.fromFile = "/run/secrets/eg_password";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.podman.containers.${name} = {
      image = "ghcr.io/vogler/free-games-claimer:latest";
      volumes = [
        "${storage}/data:/fgc/data"
      ];

      port = 6080;
      traefik.name = name;
      homepage = {
        inherit category;
        name = displayName;
        settings = {
          inherit description;
          icon = "sh-free-games-claimer";
        };
      };
      glance = {
        inherit category description;
        name = displayName;
        id = name;
        icon = "sh:free-games-claimers";
      };
    };
  };
}
