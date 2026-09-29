# 2-in-1 support: automatic screen rotation and an on-screen keyboard.
#
# Hyprland has no built-in auto-rotation, so this is the standard two-piece
# stack: iio-sensor-proxy reads the accelerometer, iio-hyprland listens on
# D-Bus and rotates the display. nixpkgs ships modules for both — notably
# programs.iio-hyprland, which also turns on hardware.sensor.iio for us
# (spelled out below anyway, since it is the load-bearing half).
{ pkgs, ... }:

{
  # Exposes the accelerometer over D-Bus as net.hadess.SensorProxy and pulls in
  # hid-sensor-hub for the initrd. On this Dell the sensor is in the base rather
  # than the display, so the naive orientation mapping can come out rotated;
  # iio-hyprland exposes --transform for exactly that correction.
  hardware.sensor.iio.enable = true;

  # Adds pkgs.iio-hyprland to the system PATH. It is a package, not a service,
  # so it is launched from hyprland.conf with `exec-once = iio-hyprland`.
  # It rotates touch and stylus devices alongside the monitor — rotating the
  # monitor alone would leave touch input in the original orientation.
  programs.iio-hyprland.enable = true;

  # On-screen keyboard for tablet mode. The binary is wvkbd-mobintl (the mobile
  # international layout). There is no NixOS module; it is toggled from a
  # hyprland keybind or the convertible switch.
  #
  # Note: wvkbd's --auto flag needs zwp_input_method_v2, which Hyprland does not
  # implement, so it is driven manually rather than automatically.
  environment.systemPackages = [ pkgs.wvkbd ];
}
