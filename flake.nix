{
  description = "Perfect Dark port - A work-in-progress port of the Perfect Dark decompilation to modern platforms";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      let
        mkPerfectDark = romid: pkgs.stdenv.mkDerivation {
          pname = "perfect-dark";
          version = "unstable";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            gcc
            python3
            pkg-config
          ];

          buildInputs = with pkgs; [
            SDL2
            zlib
            libGL
          ];

          postPatch = ''
            # Make build tools executable
            chmod +x tools/assetmgr/mklang
            chmod +x tools/assetmgr/mkanims
            chmod +x tools/assetmgr/mkpads
            chmod +x tools/assetmgr/mksequences
            chmod +x tools/assetmgr/mktextures
            chmod +x tools/assetmgr/mktiles
            patchShebangs tools/
          '';

          configurePhase = ''
            # Nix's GCC treats warnings as errors by default, unlike regular Linux builds
            export NIX_CFLAGS_COMPILE="-Wno-error=format-security -Wno-error=maybe-uninitialized"
            cmake -G"Unix Makefiles" -Bbuild . ${if romid != "ntsc-final" then "-DROMID=${romid}" else ""}
          '';

          buildPhase = ''
            cmake --build build -j$NIX_BUILD_CORES
          '';

          installPhase = let
            arch = if system == "x86_64-linux" then "x86_64" else if system == "i686-linux" then "i686" else "x86_64";
            suffix = if romid == "pal-final" then ".pal" else if romid == "jpn-final" then ".jpn" else "";
            binaryName = "pd${suffix}.${arch}";
          in ''
            mkdir -p $out/bin
            cp build/${binaryName} $out/bin/perfect-dark${suffix}
          '';

          meta = with pkgs.lib; {
            description = "Perfect Dark port to modern platforms${if romid != "ntsc-final" then " (${romid})" else ""}";
            homepage = "https://github.com/fgsfdsfgs/perfect_dark";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "perfect-dark-all";
          version = "unstable";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            gcc
            python3
            pkg-config
          ];

          buildInputs = with pkgs; [
            SDL2
            zlib
            libGL
          ];

          postPatch = ''
            # Make build tools executable
            chmod +x tools/assetmgr/mklang
            chmod +x tools/assetmgr/mkanims
            chmod +x tools/assetmgr/mkpads
            chmod +x tools/assetmgr/mksequences
            chmod +x tools/assetmgr/mktextures
            chmod +x tools/assetmgr/mktiles
            patchShebangs tools/
          '';

          configurePhase = ''
            # Nix's GCC treats warnings as errors by default, unlike regular Linux builds
            export NIX_CFLAGS_COMPILE="-Wno-error=format-security -Wno-error=maybe-uninitialized"
            
            # Build NTSC
            cmake -G"Unix Makefiles" -Bbuild-ntsc .
            
            # Build PAL
            cmake -G"Unix Makefiles" -Bbuild-pal . -DROMID=pal-final
            
            # Build JPN
            cmake -G"Unix Makefiles" -Bbuild-jpn . -DROMID=jpn-final
          '';

          buildPhase = ''
            cmake --build build-ntsc -j$NIX_BUILD_CORES
            cmake --build build-pal -j$NIX_BUILD_CORES
            cmake --build build-jpn -j$NIX_BUILD_CORES
          '';

          installPhase = let
            arch = if system == "x86_64-linux" then "x86_64" else if system == "i686-linux" then "i686" else "x86_64";
          in ''
            mkdir -p $out/bin
            cp build-ntsc/pd.${arch} $out/bin/perfect-dark
            cp build-pal/pd.pal.${arch} $out/bin/perfect-dark.pal
            cp build-jpn/pd.jpn.${arch} $out/bin/perfect-dark.jpn
          '';

          meta = with pkgs.lib; {
            description = "Perfect Dark port to modern platforms (all regions)";
            homepage = "https://github.com/fgsfdsfgs/perfect_dark";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };

        packages.ntsc = mkPerfectDark "ntsc-final";
        packages.pal = mkPerfectDark "pal-final";
        packages.jpn = mkPerfectDark "jpn-final";

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/perfect-dark";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cmake
            gcc
            python3
            SDL2
            zlib
            libGL
            pkg-config
            git
          ];

          shellHook = ''
            echo "Perfect Dark development environment"
            echo "Run 'cmake -G\"Unix Makefiles\" -Bbuild .' to configure"
            echo "Run 'cmake --build build -j4' to build"
          '';
        };
      });
}
