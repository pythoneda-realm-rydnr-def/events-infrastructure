# flake.nix
#
# This file packages pythoneda-realm-rydnr/events-infrastructure as a Nix flake.
#
# Copyright (C) 2023-today rydnr's pythoneda-realm-rydnr-def/events-infrastructure
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
{
  description = "Infrastructure layer of pythoneda-realm-rydnr/events";
  inputs = rec {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixos.url = "github:NixOS/nixpkgs/23.11";
    pythoneda-realm-rydnr-events = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-banner.follows =
        "pythoneda-shared-banner";
      inputs.pythoneda-shared-domain.follows =
        "pythoneda-shared-domain";
      url = "github:pythoneda-realm-rydnr-def/events/0.0.18";
    };
    pythoneda-shared-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      url = "github:pythoneda-shared-def/banner/0.0.46";
    };
    pythoneda-shared-domain = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-banner.follows =
        "pythoneda-shared-banner";
      url = "github:pythoneda-shared-def/domain/0.0.26";
    };
    pythoneda-shared-infrastructure = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-banner.follows =
        "pythoneda-shared-banner";
      inputs.pythoneda-shared-domain.follows =
        "pythoneda-shared-domain";
      url = "github:pythoneda-shared-def/infrastructure/0.0.22";
    };
  };
  outputs = inputs:
    with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let
        org = "pythoneda-realm-rydnr";
        repo = "events-infrastructure";
        version = "0.0.6";
        sha256 = "1ix17hn98yv5h33jh96w607pvqy8s34slplb1wai8jvzxr0iml9q";
        pname = "${org}-${repo}";
        pythonpackage = "pythoneda.realm.rydnr.events.infrastructure";
        pkgs = import nixos { inherit system; };
        description = "Infrastructure layer of pythoneda-realm-rydnr/events";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = with pkgs.lib.maintainers;
          [ "rydnr <github@acm-sl.org>" ];
        archRole = "E";
        space = "D";
        layer = "I";
        nixosVersion = builtins.readFile "${nixos}/.version";
        nixpkgsRelease = "nixos-${nixosVersion}";
        shared = import "${pythoneda-shared-banner}/nix/shared.nix";
        pythoneda-realm-rydnr-events-infrastructure-for = { python
          , pythoneda-realm-rydnr-events, pythoneda-shared-domain
          , pythoneda-shared-infrastructure }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTemplateFile = ./pyprojecttoml.template;
            pyprojectTemplate = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              dbusNextVersion = python.pkgs.dbus-next.version;
              inherit homepage pname pythonMajorMinorVersion pythonpackage
                version;
              package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
              pythonedaRealmRydnrEventsVersion =
                pythoneda-realm-rydnr-events.version;
              pythonedaSharedDomainVersion =
                pythoneda-shared-domain.version;
              pythonedaSharedInfrastructureVersion =
                pythoneda-shared-infrastructure.version;
              src = pyprojectTemplateFile;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              dbus-next
              pythoneda-realm-rydnr-events
              pythoneda-shared-domain
              pythoneda-shared-infrastructure
            ];

            pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              cp -r ${src} .
              sourceRoot=$(ls | grep -v env-vars)
              chmod +w $sourceRoot
              cp ${pyprojectTemplate} $sourceRoot/pyproject.toml
            '';

            postInstall = ''
              pushd /build/$sourceRoot
              for f in $(find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              popd
              mkdir $out/dist
              cp dist/${wheelName} $out/dist
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        defaultPackage = packages.default;
        devShells = rec {
          default = pythoneda-realm-rydnr-events-infrastructure-default;
          pythoneda-realm-rydnr-events-infrastructure-default =
            pythoneda-realm-rydnr-events-infrastructure-python311;
          pythoneda-realm-rydnr-events-infrastructure-python38 =
            shared.devShell-for {
              banner = "${
                  pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38
                }/bin/banner.sh";
              extra-namespaces = "";
              nixpkgs-release = nixpkgsRelease;
              package =
                packages.pythoneda-realm-rydnr-events-infrastructure-python38;
              python = pkgs.python38;
              pythoneda-shared-banner =
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python38;
              inherit archRole layer org pkgs repo space;
            };
          pythoneda-realm-rydnr-events-infrastructure-python39 =
            shared.devShell-for {
              banner = "${
                  pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39
                }/bin/banner.sh";
              extra-namespaces = "";
              nixpkgs-release = nixpkgsRelease;
              package =
                packages.pythoneda-realm-rydnr-events-infrastructure-python39;
              python = pkgs.python39;
              pythoneda-shared-banner =
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python39;
              inherit archRole layer org pkgs repo space;
            };
          pythoneda-realm-rydnr-events-infrastructure-python310 =
            shared.devShell-for {
              banner = "${
                  pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310
                }/bin/banner.sh";
              extra-namespaces = "";
              nixpkgs-release = nixpkgsRelease;
              package =
                packages.pythoneda-realm-rydnr-events-infrastructure-python310;
              python = pkgs.python310;
              pythoneda-shared-banner =
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python310;
              inherit archRole layer org pkgs repo space;
            };
          pythoneda-realm-rydnr-events-infrastructure-python311 =
            shared.devShell-for {
              banner = "${
                  pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311
                }/bin/banner.sh";
              extra-namespaces = "";
              nixpkgs-release = nixpkgsRelease;
              package =
                packages.pythoneda-realm-rydnr-events-infrastructure-python311;
              python = pkgs.python311;
              pythoneda-shared-banner =
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python311;
              inherit archRole layer org pkgs repo space;
            };
        };
        packages = rec {
          default = pythoneda-realm-rydnr-events-infrastructure-default;
          pythoneda-realm-rydnr-events-infrastructure-default =
            pythoneda-realm-rydnr-events-infrastructure-python311;
          pythoneda-realm-rydnr-events-infrastructure-python38 =
            pythoneda-realm-rydnr-events-infrastructure-for {
              python = pkgs.python38;
              pythoneda-realm-rydnr-events =
                pythoneda-realm-rydnr-events.packages.${system}.pythoneda-realm-rydnr-events-python38;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python38;
              pythoneda-shared-infrastructure =
                pythoneda-shared-infrastructure.packages.${system}.pythoneda-shared-infrastructure-python38;
            };
          pythoneda-realm-rydnr-events-infrastructure-python39 =
            pythoneda-realm-rydnr-events-infrastructure-for {
              python = pkgs.python39;
              pythoneda-realm-rydnr-events =
                pythoneda-realm-rydnr-events.packages.${system}.pythoneda-realm-rydnr-events-python39;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python39;
              pythoneda-shared-infrastructure =
                pythoneda-shared-infrastructure.packages.${system}.pythoneda-shared-infrastructure-python39;
            };
          pythoneda-realm-rydnr-events-infrastructure-python310 =
            pythoneda-realm-rydnr-events-infrastructure-for {
              python = pkgs.python310;
              pythoneda-realm-rydnr-events =
                pythoneda-realm-rydnr-events.packages.${system}.pythoneda-realm-rydnr-events-python310;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python310;
              pythoneda-shared-infrastructure =
                pythoneda-shared-infrastructure.packages.${system}.pythoneda-shared-infrastructure-python310;
            };
          pythoneda-realm-rydnr-events-infrastructure-python311 =
            pythoneda-realm-rydnr-events-infrastructure-for {
              python = pkgs.python311;
              pythoneda-realm-rydnr-events =
                pythoneda-realm-rydnr-events.packages.${system}.pythoneda-realm-rydnr-events-python311;
              pythoneda-shared-domain =
                pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python311;
              pythoneda-shared-infrastructure =
                pythoneda-shared-infrastructure.packages.${system}.pythoneda-shared-infrastructure-python311;
            };
        };
      });
}
