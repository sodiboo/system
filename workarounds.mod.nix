{...}: {
  sodium.modules = [
    ({pkgs, ...}: {
      boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
    })
  ];

  nitrogen.modules = [
    ({pkgs, ...}: {
      boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    })
  ];
}
