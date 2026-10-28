# Rex personal server for maxrn, run by home-manager as the systemd user service
# rex. It joins the tailnet as its own device (built-in Tailscale) at
# https://beholder-rex.diplodocus-barley.ts.net. The first start needs a sign-in:
# the link is in `rex server status` (as maxrn) and `journalctl --user -u rex`.
#
# Deploys never restart a running server, since that ends every session. After a
# Rex update, run `systemctl --user restart rex` as maxrn when convenient. The
# module also always warns about `loginctl enable-linger`; linger below covers it.
{
  config,
  rex,
  ...
}:
{
  users.users.maxrn = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    # Start the user manager, and so rex, at boot rather than at the first login.
    linger = true;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.maxrn = {
    imports = [ rex.homeManagerModules.default ];

    programs.rex.enable = true;
    services.rex = {
      enable = true;
      tailscale = {
        enable = true;
        hostname = "beholder-rex";
      };
    };

    # home-manager writes ~/.ssh/config only when this is on, and programs.rex
    # adds the xterm-rex fallback to it.
    programs.ssh.enable = true;
    programs.ssh.enableDefaultConfig = false;

    home.stateVersion = "26.05";
  };
}
