(import <nixpkgs> { }).callPackage

  (
    {
      lib,
      stdenv,
      fetchFromGitHub,
      cmake,
      zlib,
      pkg-config,
      llvm,
      libbfd,
      re2c,
      bison,
      rapidjson,
      libffi,
      libxml2,
      llvmPackages_16,
      xonsh,
    }:

    stdenv.mkDerivation rec {
      pname = "lpython";
      version = "0.22.0";

      src = fetchFromGitHub {
        owner = "lcompilers";
        repo = "lpython";
        rev = "v${version}";
        hash = "sha256-bZplo9CT0FUEUhaThMbTUGp9elZiMMbEUPLrt4nD9M8=";
      };

      buildInputs = [
        bison
        zlib.static
        libxml2
        libffi
        libbfd
        re2c
        rapidjson
        xonsh
      ];
      enableParallelBuilding = false;
      nativeBuildInputs = [
        cmake
        pkg-config
        llvmPackages_16.llvm.dev
      ];
      cmakeFlags = [ "-DWITH_LLVM=yes" ];
      preConfigure = ''
        echo $version > version
        sed -i "s/ci\/version.sh//g" build0.sh
        bash build0.sh
      '';
      preBuild = ''

      '';
      meta = with lib; {
        description = "Python compiler";
        homepage = "https://github.com/lcompilers/lpython";
        license = licenses.bsd3;
        maintainers = with maintainers; [ ];
        mainProgram = "lpython";
        platforms = platforms.all;
      };
    }
  )
  { }
