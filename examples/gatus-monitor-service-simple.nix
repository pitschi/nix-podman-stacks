/*
You can monitor the status of a service by adding it to the Gatus endpoint configuration.
This can be simplified by using a containers `gatus` option.

When enabled, by default the endpoint settings configured via `nps.stacks.gatus.defaultEndpoint`
are used. You can override individial settings as needed (e.g. timeout, conditions).

The endpoint added to the Gatus configuration will be the domain of the service that is handled by Traefik.
This can also be overriden by setting the `url` option in the `gatus.settings` attribute.
The most basic example to enable Gatus monitoring:
*/
{config, ...}: {
  nps.stacks.streaming.containers.sonarr.gatus.enable = true;

  # The above is equivalent to adding the service to Gatus via its settings option:
  nps.stacks.gatus = {
    settings.endpoints = let
      sonarrCfg = config.nps.stacks.streaming.containers.sonarr;
    in [
      {
        name = sonarrCfg.traefik.name;
        url = sonarrCfg.reverseProxy.serviceUrl;
      }
    ];
  };
}
