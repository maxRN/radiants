{ pkgs, config, ... }:
let
  dropbox_auth_key = config.users.users.root.home + "/.local/share/python_keyring/keyring_pass.cfg";
in
{
  # This creates the file in /etc and you can symlink it
  environment.etc."root/.config/maestral/maestral.ini" = {
    text = builtins.readFile ./maestral.ini;
    mode = "0644";
  };
  # see https://github.com/samschott/maestral/issues/992
  systemd.services.maestral = {
    description = "Maestral";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.maestral}/bin/maestral start";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
      KillMode = "process";
      Restart = "on-failure";
      ExecStartPre = [
        "${pkgs.bash}/bin/bash -c 'mkdir -p /root/.config/maestral'"
        "${pkgs.bash}/bin/bash -c 'echo executing pre start'"
        "${pkgs.bash}/bin/bash -c 'cat /etc/root/.config/maestral/maestral.ini > /root/.config/maestral/maestral.ini'"
      ];
    };
  };

  sops.secrets.maestral_key_file = {
    path = dropbox_auth_key;
  };
}
