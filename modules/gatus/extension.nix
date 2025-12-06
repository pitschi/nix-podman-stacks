{
  config,
  lib,
  pkgs,
  ...
}: let
  yaml = pkgs.formats.yaml {};

  gatusContainers =
    lib.filterAttrs (k: c: c.gatus.enable && c.gatus.settings != {})
    config.services.podman.containers;
  endpointSettings = lib.mapAttrs (name: c: c.gatus.settings) gatusContainers |> lib.attrValues;
in {
  config = lib.mkIf (gatusContainers != {}) {
    nps.stacks.gatus.settings.endpoints = endpointSettings;
  };

  options.services.podman.containers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      ...
    }: {
      options.gatus = with lib; {
        enable = mkEnableOption "gatus";
        settings = mkOption {
          type = yaml.type;
          default = {};
          description = ''
            Endpoint Settings for the container.
            Will be added to the Gatus endpoint configuration.

            See <https://github.com/TwiN/gatus?tab=readme-ov-file#endpoints>
          '';
        };
      };

      config = lib.mkIf (config.gatus.enable) {
        gatus.settings = {
          name = lib.mkDefault name;
          url = lib.mkDefault config.reverseProxy.serviceUrl;
        };
      };
    }));
  };
}
