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
  llvmPackages_18, # for darwin (24.11 stdenv.cc = clang16  )
  autoconf,
  outputsSupport ? true, # outputs screen
  visualizerSupport ? false,
  fftw, # visualizer screen
  clockSupport ? true, # clock screen
  taglibSupport ? true,
  taglib, # tag editor
}:
let
  #Darwin's stdenv.cc is clang 16 doesn't fully support c++20
  #and nixpkgs(25.05 would use llvm19 )
  stdenv' = if stdenv.isDarwin then llvmPackages_18.stdenv else stdenv;
in
stdenv'.mkDerivation rec {
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
    ++ (lib.optional outputsSupport "--enable-outputs")
    ++ (lib.optional visualizerSupport "--enable-visualizer --with-fftw")
    ++ (lib.optional clockSupport "--enable-clock")
    ++ (lib.optional taglibSupport "--with-taglib");

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    pkg-config
  ] ++ lib.optional taglibSupport taglib;

  buildInputs = [
    boost
    libmpdclient
    ncurses
    readline
    libiconv
    icu
    curl
  ] ++ (lib.optional visualizerSupport fftw) ++ (lib.optional taglibSupport taglib);

  preConfigure = ''
    ./autogen.sh
  '';
  # + lib.optionalString stdenv.isDarwin ''
  #   # clang16(24.11 darwin) doesn't support c++20
  #   substituteInPlace ./configure \
  #     --replace-fail "std=c++20" "std=c++17"
  # '';

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
