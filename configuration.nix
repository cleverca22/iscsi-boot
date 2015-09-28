{ ... }:

{
  imports = [ ./iscsi-boot.nix ];
  fileSystems."/" = {
    device = "LABEL=nixos";
    iscsi = {
      enable = true;
      host = "10.0.2.2";
      lun = "iqn.2015-09.ramboot:test1";
    };
  };
  boot = {
    loader.grub.enable = false;
    initrd = {
      kernelModules = [ "e1000" "ext4" ];
      iscsi = {
        netDev = "eth0";
        initiatorName = "initiator";
      };
    };
  };
  networking = {
    firewall.enable = false;
    interfaces.eth0.ipAddress = "10.0.2.15";
    interfaces.eth0.prefixLength = 24;
    defaultGateway = "10.0.2.2";
    nameservers = [ "10.0.2.3" ];
  };
  systemd.services.network-address-eth0.wantedBy = [ "local-fs.target" ];
}
