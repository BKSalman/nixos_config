{
  stdenv,
  lib,
  requireFile,
  unzip,
  appimage-run,
  addOpenGLRunpath,
  libGLU,
  xorg,
  buildFHSEnv,
  buildFHSEnvChroot,
  bash,
  writeText,
  ocl-icd,
  xkeyboard_config,
  glib,
  libarchive,
  libxcrypt,
  python2,
  aprutil,
}: let
  davinci = (
    stdenv.mkDerivation rec {
      pname = "davinci-resolve";
      version = "18.1.4";

      nativeBuildInputs = [
        unzip
        (appimage-run.override {buildFHSEnv = buildFHSEnvChroot;})
        addOpenGLRunpath
      ];

      # Pretty sure, there are missing dependencies ...
      buildInputs = [libGLU xorg.libXxf86vm];

      src = requireFile rec {
        name = "DaVinci_Resolve_${version}_Linux.zip";
        url = "https://www.blackmagicdesign.com/products/davinciresolve/";
        sha256 = "08p5g7ss405ncayw1z1ml1p9b314yyr2wj16vbad9ivkkjj3nz3d";

        message = ''
          Unfortunately, DaVinci Resolve cannot be downloaded automatically. Please
          visit ${url} to download it yourself, then add it to the Nix store by
          running the following comand:

            $ nix-prefetch-url --type sha256 file://$(pwd)/${name} ${sha256}
        '';
      };

      sourceRoot = ".";

      installPhase = ''
        runHook preInstall

        export HOME=$PWD/home
        mkdir -p $HOME

        mkdir -p $out
        appimage-run ./DaVinci_Resolve_${version}_Linux.run -i -y -n -C $out

        mkdir -p $out/{configs,DolbyVision,easyDCP,Fairlight,GPUCache,logs,Media,"Resolve Disk Database",.crashreport,.license,.LUT}
        runHook postInstall
      '';

      dontStrip = true;

      postFixup = ''
        for program in $out/bin/*; do
          isELF "$program" || continue
          addOpenGLRunpath "$program"
        done

        for program in $out/libs/*; do
          isELF "$program" || continue
          if [[ "$program" != *"libcudnn_cnn_infer"* ]];then
            echo $program
            addOpenGLRunpath "$program"
          fi
        done
        ln -s $out/libs/libcrypto.so.1.1 $out/libs/libcrypt.so.1
      '';
    }
  );
in
  buildFHSEnv {
    name = "davinci-resolve";
    targetPkgs = pkgs:
      with pkgs; [
        alsa-lib
        davinci
        dbus
        expat
        fontconfig
        freetype
        glib
        libarchive
        libcap
        libGL
        libGLU
        librsvg
        libuuid
        libxkbcommon
        nspr
        nss
        ocl-icd
        opencl-headers
        python3
        udev
        xorg.libICE
        xorg.libSM
        xorg.libX11
        xorg.libxcb
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libXxf86vm
        xorg.xcbutil
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        xorg.xkeyboardconfig
        zlib
        librsvg
        libGLU
        libGL
        xorg.libXxf86vm
        libxkbcommon
        udev
        opencl-headers
        expat
        libuuid
        bzip2
        libtool
        ocl-icd
        libarchive
        libxcrypt # provides libcrypt.so.1
        xdg-utils # xdg-open needed to open URLs
        python2
        # currently they want python 3.6 which is EOL
        #python3
        aprutil
      ];

    runScript = "${bash}/bin/bash ${
      writeText "davinci-wrapper"
      ''
        export QT_XKB_CONFIG_ROOT="${xkeyboard_config}/share/X11/xkb"
        export QT_PLUGIN_PATH="${davinci}/libs/plugins:$QT_PLUGIN_PATH"
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${davinci}/libs
        ${davinci}/bin/resolve
      ''
    }";

    meta = with lib; {
      description = "Professional Video Editing, Color, Effects and Audio Post";
      homepage = "https://www.blackmagicdesign.com/products/davinciresolve/";
      license = licenses.unfree;
      maintainers = with maintainers; [jshcmpbll];
      platforms = platforms.linux;
    };
  }
