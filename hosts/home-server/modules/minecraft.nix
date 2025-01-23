# a very bad module for running minecraft servers downloaded manually because everything automatic sucks
{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    minecraft.enable = lib.mkEnableOption "Enable Minecraft server";
  };

  config = lib.mkIf config.minecraft.enable {
    environment.systemPackages = with pkgs; [
      jdk17_headless
    ];
    networking.firewall.allowedTCPPorts = [25565];
    systemd.services.prominence2 = {
      enable = true;
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        User = "salman";
        WorkingDirectory = "/home/salman/prominence2";
      };
      script = ''
        if [ ! -f /home/salman/prominence2/start.sh ]; then
          echo "Server start script is not found"
          exit 1
        fi

        export JAVA_ARGS="-Xms4G -Xmx8G -XX:+UseG1GC -XX:+ParallelRefProcEnabled \
          -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions \
          -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 \
          -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \
          -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \
          -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 \
          -XX:G1MixedGCLiveThresholdPercent=90 \
          -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 \
          -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \
          -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"

        /home/salman/prominence2/start.sh
      '';

      path = with pkgs; [
        bash
        curl
        jdk17_headless
      ];
    };
  };
}
