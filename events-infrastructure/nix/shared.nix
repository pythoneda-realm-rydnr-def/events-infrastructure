rec {
  shellHook-for =
    { package, python, pythoneda-shared-pythoneda-domain, nixpkgsRelease }:
    let
      pythonVersionParts = builtins.splitVersion python.version;
      pythonMajorVersion = builtins.head pythonVersionParts;
      pythonMajorMinorVersion =
        "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
    in ''
      export PNAME="${package.pname}";
      export PVERSION="${package.version}";
      export PYNAME="${python.name}";
      export PYVERSION="${pythonMajorMinorVersion}";
      export NIXPKGSRELEASE="${nixpkgsRelease}";
      export PYTHONEDA="${pythoneda-shared-pythoneda-domain}";
      export PS1="\033[37m[\[\033[01;33m\]\$PNAME-\$PVERSION\033[01;37m|\033[01;32m\]\$PYNAME\]\033[37m|\[\033[00m\]\[\033[01;34m\]\W\033[37m]\033[31m\$\[\033[00m\] ";
      echo;
      echo -e " \033[32m             _   _                          \033[35m_\033[0m";
      echo -e " \033[32m            | | | |                        \033[35m| | \033[37mGPLv3\033[0m";
      echo -e " \033[32m _ __  _   _| |_| |__   ___  _ __   \033[34m___  \033[35m__| | \033[36m__ _ \033[32mhttps://pythoneda.github.io\033[0m\033[0m";
      echo -e " \033[32m| '_ \| | | | __| '_ \ / _ \| '_ \ \033[34m/ _ \\\\\033[35m/ _\` |\033[36m/ _\` |\033[33mhttps://github.com/pythoneda-realm-rydnr/events-infrastructure/tree/$PVERSION\033[0m";
      echo -e " \033[32m| |_) | |_| | |_| | | | (_) | | | |\033[34m  __/\033[35m (_| |\033[36m (_| |\033[34mhttps://github.com/pythoneda-realm-rydnr\033[0m";
      echo -e " \033[32m| .__/ \__, |\__|_| |_|\___/|_| |_|\033[34m\___|\033[35m\__,_|\033[36m\__,_|\033[35mhttps://github.com/nixos/nixpkgs/tree/$NIXPKGSRELEASE\033[0m";
      echo -e " \033[32m| |     __/ |        \033[34mPYTHONEDA-REALM-RYDNR          \033[36mhttps://docs.python.org/$PYVERSION\033[0m";
      echo -e " \033[32m|_|\033[37m \033[31mR\033[36mI\033[32m |___/         \033[33mEVENTS-INFRASTRUCTURE          \033[37mhttps://patreon.com/rydnr\033[0m";
      echo;
      echo " Thank you for using pythoneda-realm-rydnr/events-infrastructure, and for your appreciation of free software.";
      echo;
      export PYTHONPATH="$(python $PYTHONEDA/dist/scripts/fix_pythonpath.py)";
    '';
  devShell-for = { package, pkgs, python, pythoneda-shared-pythoneda-domain
    , nixpkgsRelease }:
    pkgs.mkShell {
      buildInputs = [ package ];
      shellHook = shellHook-for {
        inherit package python pythoneda-shared-pythoneda-domain nixpkgsRelease;
      };
    };
}
