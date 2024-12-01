{ lib
, stdenv
, fetchFromGitHub
, cmake
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

  nativeBuildInputs = [
    cmake
  ];

  meta = with lib; {
    description = "Python compiler";
    homepage = "https://github.com/lcompilers/lpython";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
    mainProgram = "lpython";
    platforms = platforms.all;
  };
}
