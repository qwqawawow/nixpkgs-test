{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "empiriqa";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "ynqa";
    repo = "empiriqa";
    rev = "v${version}";
    hash = "sha256-TLjbhNUAykkKbChbVkm5pAC63RpmIxQjy5vFTom3XKQ=";
  };

  cargoHash = "sha256-Walh+rR42AGMEvWXNawXn0Mg97ctyw2goidBQZDR4s0=";

  useFetchCargoVendor = true;

  meta = {
    # TODO:
    description = "";

    longDescription = ''
      empiriqa (command name is epiq) is a tool for interactively manipulating UNIX pipelines |. 
      You can individually edit, add, delete, and toggle disable/enable for each pipeline stage.
      It allows you to easily and efficiently experiment with data processing and analysis using commands.
      Additionally, you can execute commands with continuous output streams like tail -f.
      empiriqa can be considered a generalization of tools like jnv (interactive JSON filter using jq) and sig (interactive grep for streaming).
      While jnv focuses on JSON data manipulation and sig specializes in grep searches, empiriqa extends the interactive approach to all UNIX pipeline operations, providing a more versatile platform for command-line experimentation.
    '';
    homepage = "https://codeberg.org/lukeflo/bibiman";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];

    # TODO:
    mainProgram = "";
  };
}
