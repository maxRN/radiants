{
  lib,
  config,
  ...
}:
with lib;
{

  options.services.audiobookshelf = {
    REFRESH_TOKEN_EXPIRY = mkOption {
      description = "the refresh token expiry in seconds";
      default = 7 * 24 * 60 * 60; # 7 days
      type = types.number;
    };
  };

  config = mkIf config.services.audiobookshelf.enable {
    systemd.services.audiobookshelf = {
      environment = {
        REFRESH_TOKEN_EXPIRY = toString config.services.audiobookshelf.REFRESH_TOKEN_EXPIRY;
      };
    };
  };
}
