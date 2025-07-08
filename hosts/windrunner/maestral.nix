{ pkgs, config, ... }:
let
  dropbox_auth_key = config.users.users.root.home + "/.local/share/python_keyring/keyring_pass.cfg";
  maestral_config_service = "maestral_config";
in
{
  systemd.user.services.maestral = {
    description = "Maestral";
    wantedBy = [ "default.target" ];
    after = [ (maestral_config_service + ".service") ];
    serviceConfig = {
      ExecStart = "${pkgs.maestral}/bin/maestral start";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
      KillMode = "process";
      Restart = "on-failure";
    };
  };

  systemd.user.services."${maestral_config_service}" = {
    description = "Maestral config file";
    wantedBy = [ "default.target" ];
    script = ''
      echo "running maestral config service!"
      cat ${builtins.readFile ./maestral.ini} > maestral.ini
    '';
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = config.users.users.root.home + "/.config/maestral/";
    };
  };

  sops.secrets.maestral_key = {
    path = dropbox_auth_key;
  };
}
