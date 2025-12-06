/*
To override the default settings of a container when enabling Gatus (e.g. the url),
the settings attribute can be used, which is directly mapped to an endpointentry in the in Gatus configuration.

For example to set the url to a custom one and change the condition:
*/
{config, ...}: {
  nps.stacks = let
    cfg = config.nps.stacks.aiostreams.containers.aiostreams;
  in {
    aiostreams.containers.aiostreams.gatus = {
      enable = true;
      settings = {
        url = "${cfg.reverseProxy.serviceUrl}/api/v1/status";
        conditions = [
          "[BODY].success == true"
        ];
      };
    };
  };
}
