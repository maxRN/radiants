{ config, ... }:
let
  tmPath = "/mnt/share/tm_share";
in
{
  users.users.samba-user = {
    name = "samba-user";
    isNormalUser = true;
  };

  users.groups.networker = {
    members = [
      config.users.users.samba-user.name
    ];
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      "tm_share" = {
        "path" = tmPath;
        "valid users" = config.users.users.samba-user.name;
        "public" = "no";
        "writeable" = "yes";
        "read only" = "no";
        "force user" = config.users.users.samba-user.name;
        # Below are the most imporant for macOS compatibility
        # Change the above to suit your needs
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        #"use sendfile" = "yes";
        #"max protocol" = "smb2";
        # note: localhost is the ipv6 localhost ::1
        # "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        # "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
    nssmdns4 = true;
    # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
    enable = true;
    openFirewall = true;
  };

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  # Ensure Time Machine can discover the share without `tmutil`
  services.avahi = {
    extraServiceFiles = {
      timemachine = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
            <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <!-- 
              change tm_share to share name, if you changed it. 
            --> 
            <txt-record>dk0=adVN=tm_share,adVF=0x82</txt-record>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
          </service>
        </service-group>
      '';
    };
  };

  # Share path must be owned by the respective unix user. (e.g. ❯ chown -R samba: /samba)
  systemd.tmpfiles.rules = [
    "d ${tmPath} 0755 ${config.users.users.samba-user.name} users"
  ];
}
