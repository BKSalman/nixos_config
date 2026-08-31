{
  config,
  pkgs,
  ...
}: {
  # Configure Input Method Editor (IME)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk # Crucial for GTK apps (like Firefox)
    ];
  };
}
