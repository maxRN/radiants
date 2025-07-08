{ pkgs, config, ... }:
let
  dropbox_auth_key = config.users.users.root.home + "/.local/share/python_keyring/keyring_pass.cfg";
  # maestral_config_service = "maestral_config";
in

{
  # see https://github.com/samschott/maestral/issues/992
  systemd.user.services.maestral = {
    description = "Maestral";
    wantedBy = [ "default.target" ];
    # after = [ (maestral_config_service + ".service") ];
    serviceConfig = {
      ExecStart = "${pkgs.maestral}/bin/maestral start";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
      KillMode = "process";
      Restart = "on-failure";
      ExecPreStart = [
        "mkdir -p /root/.config/maestral"
        "echo 'executing pre start'"
        "echo '${builtins.readFile ./maestral.ini}'"
        "echo '${builtins.readFile ./maestral.ini}' > /root/.config/maestral/maestral.ini"
      ];
    };
  };

  # systemd.user.services."${maestral_config_service}" = {
  #   description = "Maestral config file";
  #   after = [ "multi-user.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   script = ''
  #     echo "running maestral config service!"
  #     echo "testing" > /root/test.file
  #     echo "${builtins.readFile ./maestral.ini}" > /root/.config/maestral/maestral.ini
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     User = "root";
  #   };
  # };

  sops.secrets.maestral_key_file = {
    path = dropbox_auth_key;
  };
}
