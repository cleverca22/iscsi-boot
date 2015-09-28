{ system ? builtins.currentSystem }:
# vim: expandtab:noai:ts=2:sw=2

let
  configuration = {config, lib, pkgs, ...}: {
    system.build.testImage = import ./make-disk-image.nix {
      inherit pkgs lib config;
      diskSize = 1024;
      partitioned = false;
      configFile = pkgs.writeText "configuration.nix"
        ''
          { }
        '';
    };
    system.build.vm = pkgs.runCommand "nixos-vm" { preferLocalBuild = true; }
      ''
        mkdir -p $out/bin
        ln -sv ${config.system.build.toplevel} $out/system
        ln -sv ${config.system.build.testImage}/nixos.img $out/disk.img
        ln -sv ${pkgs.writeScript "run-nixos-vm"
          ''
            #!/bin/bash
            ${pkgs.qemu_kvm}/bin/qemu-kvm -m 256 -kernel ${config.system.build.toplevel}/kernel -initrd ${config.system.build.toplevel}/initrd \
              -append "$(cat ${config.system.build.toplevel}/kernel-params) init=${config.system.build.toplevel}/init console=ttyS0 boot.shell_on_fail" \
              -nographic -no-reboot \
              -net nic,vlan=0,model=e1000 -net user,vlan=0
          ''} $out/bin/run-vm
      '';
    imports = [ ./configuration.nix ];
    nixpkgs.config.packageOverrides = pkgs: rec {
      open-iscsi = pkgs.callPackage ./open-iscsi.nix {};
    };
  };
  eval = import <nixos/lib/eval-config.nix> {
    inherit system;
    modules = [ configuration ];
  };
in
{
  image = eval.config.system.build.testImage;
  system = eval.config.system.build.toplevel;
  vm = eval.config.system.build.vm;
}
