{
  cmake,
  fetchFromGitHub,
  git,
  lib,
  libffi,
  llvmPackages_18,
  makeWrapper,
  ncurses,
  python3,
  zlib,
  # *NOT* from LLVM 9!
  # The compiler used to compile Cling may affect the runtime include and lib
  # directories it expects to be run with. Cling builds against (a fork of) Clang,
  # so we prefer to use Clang as the compiler as well for consistency.
  # It would be cleanest to use LLVM 9's clang, but it errors. So, we use a later
  # version of Clang to compile, but we check out the Cling fork of Clang 9 to
  # build Cling against.
  clangStdenv,

  # For runtime C++ standard library
  gcc-unwrapped,

  # Build with debug symbols
  debug ? false,

  # Build with libc++ (LLVM) rather than stdlibc++ (GCC).
  # This is experimental and not all features work.
  useLLVMLibcxx ? clangStdenv.hostPlatform.isDarwin,
}:

let
  stdenv = clangStdenv;

  # The patched clang lives in the LLVM megarepo
  clangSrc = fetchFromGitHub {
    owner = "root-project";
    repo = "llvm-project";
    # cling-llvm18 branch
    rev = "7a9549505de385bd14dd3e15b8aa037cfdc960cf";
    sha256 = "sha256-w6Fjk1mwmAGSw420gFoeka98sx5l4hV43LfVdz2nqU4=";
    sparseCheckout = [
      "clang"
      "cmake"
    ];
  };

  unwrapped = stdenv.mkDerivation rec {
    pname = "cling-unwrapped";
    version = "1.1";

    src = "${clangSrc}";

    clingSrc = fetchFromGitHub {
      owner = "root-project";
      repo = "cling";
      #     rev = "c30873fa8abdd2acfeba6091c1e6e7b5a05a30fd";
      #sha256 = "sha256-YN8LPlpD4HyCmoEDECn8li8VF2rsjoHbx+njrd4u9KA=";
      rev = "refs/tags/v${version}";
      sha256="sha256-MBkHU4B1qPTmfLjBh0Kvt58A+3s9TfcknHXteyVe8I0=";
    };

    prePatch = ''
      echo "add_llvm_external_project(cling)" >> clang/tools/CMakeLists.txt

      cp -r $clingSrc clang/tools/cling
      chmod -R a+w clang/tools/cling

    '';
    preConfigure = ''
      #FIXME  
      cd clang
    '';

    patches = [
      ./no-clang-cpp.patch
    ];

    nativeBuildInputs = [
      python3
      git
      cmake
    ];
    buildInputs = [
      libffi
      ncurses
      zlib
    ];

    strictDeps = true;

    cmakeFlags =
      [
        "-DLLVM_DIR=${llvmPackages_18.llvm.dev}/lib/cmake/llvm" # FIXME
        "-DLLVM_BINARY_DIR=${llvmPackages_18.llvm.out}"
        "-DLLVM_CONFIG=${llvmPackages_18.llvm.dev}/bin/llvm-config"
        "-DLLVM_LIBRARY_DIR=${llvmPackages_18.llvm.lib}/lib"
        "-DLLVM_MAIN_INCLUDE_DIR=${llvmPackages_18.llvm.dev}/include"
        "-DLLVM_TABLEGEN_EXE=${llvmPackages_18.llvm.out}/bin/llvm-tblgen"
        "-DLLVM_TOOLS_BINARY_DIR=${llvmPackages_18.llvm.out}/bin"
        "-DLLVM_BUILD_TOOLS=OFF"
        "-DLLVM_TOOL_CLING_BUILD=ON"
        "-DLLVM_INCLUDE_TESTS=OFF"

        "-DLLVM_TARGETS_TO_BUILD=host;NVPTX"
        "-DLLVM_ENABLE_RTTI=ON"

        # Setting -DCLING_INCLUDE_TESTS=ON causes the cling/tools targets to be built;
        # see cling/tools/CMakeLists.txt
        "-DCLING_INCLUDE_TESTS=ON"
        "-DCLANG-TOOLS=OFF"
      ]
      ++ lib.optionals debug [
        "-DCMAKE_BUILD_TYPE=Debug"
      ]
      ++ lib.optionals useLLVMLibcxx [
        "-DLLVM_ENABLE_LIBCXX=ON"
        "-DLLVM_ENABLE_LIBCXXABI=ON"
      ];

    CPPFLAGS = if useLLVMLibcxx then [ "-stdlib=libc++" ] else [ ];

    postInstall = lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
      mkdir -p $out/share/Jupyter
      #FIXME
      #cp -r /build/clang/tools/cling/tools/Jupyter/kernel $out/share/Jupyter
    '';

    dontStrip = debug;

    meta = with lib; {
      description = "Interactive C++ Interpreter";
      mainProgram = "cling";
      homepage = "https://root.cern/cling/";
      license = with licenses; [
        lgpl21
        ncsa
      ];
      maintainers = with maintainers; [ thomasjm ];
      platforms = platforms.unix;
    };
  };

  # Runtime flags for the C++ standard library
  cxxFlags =
    if useLLVMLibcxx then
      [
        "-I"
        "${lib.getDev llvmPackages_18.libcxx}/include/c++/v1"
        "-L"
        "${llvmPackages_18.libcxx}/lib"
        "-l"
        "${llvmPackages_18.libcxx}/lib/libc++${stdenv.hostPlatform.extensions.sharedLibrary}"
      ]
    else
      [
        "-I"
        "${gcc-unwrapped}/include/c++/${gcc-unwrapped.version}"
        "-I"
        "${gcc-unwrapped}/include/c++/${gcc-unwrapped.version}/${stdenv.hostPlatform.config}"
      ];

  # The flags passed to the wrapped cling should
  # a) prevent it from searching for system include files and libs, and
  # b) provide it with the include files and libs it needs (C and C++ standard library plus
  # its own stuff)

  # These are also exposed as cling.flags because it's handy to be able to pass them to tools
  # that wrap Cling, particularly Jupyter kernels such as xeus-cling and the built-in
  # jupyter-cling-kernel, which use Cling as a library.
  # Thus, if you're packaging a Jupyter kernel, you either need to pass these flags as extra
  # args to xcpp (for xeus-cling) or put them in the environment variable CLING_OPTS
  # (for jupyter-cling-kernel).
  flags =
    [
      "-nostdinc"
      "-nostdinc++"

      "-resource-dir"
      "${lib.getLib unwrapped}/lib/clang/18" #FIME: change the version

      "-isystem"
      "${lib.getLib unwrapped}/lib/clang/18/include"
    ]
    ++ cxxFlags
    ++ [
      # System libc
      "-isystem"
      "${lib.getDev stdenv.cc.libc}/include"

      # cling includes
      "-isystem"
      "${lib.getDev unwrapped}/include"
    ];

in

stdenv.mkDerivation {
  pname = "cling";
  version = unwrapped.version;

  nativeBuildInputs = [ makeWrapper ];
  inherit unwrapped flags;
  inherit (unwrapped) meta;

  dontUnpack = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    makeWrapper $unwrapped/bin/cling $out/bin/cling \
      --add-flags "$flags"

    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck

    output=$($out/bin/cling <<EOF
    #include <iostream>
    std::cout << "hello world" << std::endl
    EOF
    )

    echo "$output" | grep -q "Type C++ code and press enter to run it"
    echo "$output" | grep -q "hello world"

    runHook postCheck
  '';

  dontInstall = true;
}
