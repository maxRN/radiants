{
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  time.timeZone = "Europe/Berlin";
}
