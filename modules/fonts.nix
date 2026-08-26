# This module is intended for fonts

{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.symbols-only
  ];
}
