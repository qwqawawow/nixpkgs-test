{
  lib,
  stdenv,
  boost,
  libmpdclient,
  ncurses,
  pkg-config,
  readline,
  libiconv,
  fetchFromGitHub,
  icu,
  curl,
  automake,
  libtool,
  autoconf,
  outputsSupport ? true, # outputs screen
  visualizerSupport ? false,
  fftw, # visualizer screen
  clockSupport ? true, # clock screen
  taglibSupport ? true,
  taglib, # tag editor
}:

stdenv.mkDerivation rec {
  pname = "ncmpcpp";
  version = "0.10";

  src = fetchFromGitHub {
    owner = "ncmpcpp";
    repo = "ncmpcpp";
    rev = "refs/tags/${version}";
    sha256 = "sha256-HRJQ+IOQ8xP1QkPlLI+VtDUWaI2m0Aw0fCDWHhgsOLY=";
  };

  enableParallelBuilding = true;

  strictDeps = true;

  configureFlags =
    [ "BOOST_LIB_SUFFIX=" ]
    ++ lib.optional outputsSupport "--enable-outputs"
    ++ lib.optional visualizerSupport "--enable-visualizer --with-fftw"
    ++ lib.optional clockSupport "--enable-clock"
    ++ lib.optional taglibSupport "--with-taglib";

  nativeBuildInputs = [
    pkg-config
    automake
    libtool
    autoconf
  ] ++ lib.optional taglibSupport taglib;

  buildInputs = [
    boost
    libmpdclient
    ncurses
    readline
    libiconv
    icu
    curl
  ] ++ lib.optional visualizerSupport fftw ++ lib.optional taglibSupport taglib;

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with lib; {
    description = "Featureful ncurses based MPD client inspired by ncmpc";
    homepage = "https://rybczak.net/ncmpcpp/";
    changelog = "https://github.com/ncmpcpp/ncmpcpp/blob/${version}/CHANGELOG.md";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      koral
      lovek323
    ];
    platforms = platforms.all;
    mainProgram = "ncmpcpp";
  };
}
