{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "smartdns-rs";
  version = "0.8.7";

  src = fetchFromGitHub {
    owner = "mokeyish";
    repo = "smartdns-rs";
    rev = "v${version}";
    hash = "sha256-YvuwvEQLL3KTRvK7BAmUJGqPE1WdiDfleWXf3VL7IX0=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "async-socks5-0.6.0" = "sha256-jbVwQW43vRMFsejwS6F9fcpAWTcKiTYFWM0/0o7s6/g=";
      "hickory-proto-0.25.0-alpha.1" = "sha256-rCiCcn1SvB3ToOqQ7AdnVRxIEUu/xlpQV5CPklZ8Ktc=";
    };
  };

  nativeBuildInputs = [
    rustPlatform.bindgenHook
  ];

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.IOKit
    darwin.apple_sdk.frameworks.Security
  ];

  meta = {
    description = "A cross platform local DNS server (Dnsmasq like) written in rust to obtain the fastest website IP for the best Internet experience, supports DoT, DoQ, DoH, DoH3";
    homepage = "https://github.com/mokeyish/smartdns-rs";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "smartdns-rs";
  };
}
