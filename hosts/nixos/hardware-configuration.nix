{
  ...
}:
{
  # Generic bootstrap hardware config so the scaffold can evaluate and build.
  # Replace this file with the generated hardware-configuration.nix from the
  # target machine before the first real install or switch.

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usb_storage"
    "xhci_pci"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
