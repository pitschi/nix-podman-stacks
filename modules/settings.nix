{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.nps;
in {
  imports = [./extension.nix ./reverse-proxy.nix];

  options.nps = {
    package = lib.mkPackageOption pkgs "podman" {};
    enableSocket = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable the Podman socket for user services.
        Note that the socket is required for the services like Traefik or Homepage to run successfully, since they access the Podman API.

        If this is disabled and you use these services, you will need to manually enable the socket.
      '';
    };
    socketLocation = lib.mkOption {
      type = lib.types.path;
      default = "/run/user/${toString cfg.hostUid}/podman/podman.sock";
      defaultText = lib.literalExpression ''"/run/user/''${toString config.nps.hostUid}/podman/podman.sock"'';
      readOnly = true;
      description = ''
        The location of the Podman socket for user services.
        Will be passed to containers that communicate with the Podman API, such as Traefik, Homepage or Beszel.
      '';
    };
    hostUid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = ''
        UID of the host user running the containers.
        Will be used to infer the Podman socket location (XDG_RUNTIME_DIR).
      '';
    };
    defaultUid = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        UID of the user that will be used by default for containers if they allow UID configuration.
        When running rootless containers, UID 0 gets mapped to the host users UID.
      '';
    };
    defaultGid = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = ''
        GID of the user that will be used by default for containers if they allow GID configuration.
        When running rootless containers, GID 0 gets mapped to the host users GID.
      '';
    };
    defaultTz = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Etc/UTC";
      description = ''
        Default timezone for containers.
        Will be passed to all containers as `TZ` environment variable.
      '';
    };
    storageBaseDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.home.homeDirectory}/stacks";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/stacks"'';
      description = ''
        Base directory for Podman storage.
        This is where each stack will create its bind mounts for persistent data.
        For example, setting this to `/home/foo/stacks` would result in Adguard creating its bind mount at `/home/foo/stacks/adguard`.
      '';
    };
    externalStorageBaseDir = lib.mkOption {
      type = lib.types.path;
      description = ''
        Base location that will be used for larger data such as downloads or media files.
        Could be an external disk.
      '';
    };
    mediaStorageBaseDir = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.externalStorageBaseDir}/media";
      defaultText = lib.literalExpression ''"''${config.nps.externalStorageBaseDir}/media"'';
      description = ''
        Base location for larger media files.
        This is where containers like Jellyfin or Immich will store their media files.
      '';
    };
    hostIP4Address = lib.mkOption {
      type = lib.types.str;
      description = ''
        The IPv4 address which will be used in case explicit bindings are required.
      '';
    };
  };
  config = let
    anyStackEnabled =
      config.nps.stacks
      |> lib.attrValues
      |> lib.any (s: s.enable or false);
  in
    lib.mkIf anyStackEnabled {
      services.podman = {
        enable = true;
        package = cfg.package;

        settings.containers.network.dns_bind_port = 1153;
      };

      systemd.user.sockets.podman = lib.mkIf cfg.enableSocket {
        Install.WantedBy = ["sockets.target"];
        Socket = {
          SocketMode = "0660";
          ListenStream = cfg.socketLocation;
        };
      };
      systemd.user.services.podman = lib.mkIf cfg.enableSocket {
        Install.WantedBy = ["default.target"];
        Service = {
          Delegate = true;
          Type = "exec";
          KillMode = "process";
          Environment = ["LOGGING=--log-level=info"];
          ExecStart = "${lib.getExe cfg.package} $LOGGING system service";
        };
      };
    };
}
