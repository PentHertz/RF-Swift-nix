# certsync (zblurx/certsync) 0.1.6, its last release (upstream inactive since
# March 2024). It is written against Certipy 4.x internals (certipy.lib.target,
# certipy.lib.ldap, get_identifications_from_certificate, ...) that Certipy 5
# refactored away, so nixpkgs' build - which relaxes certsync's
# `certipy-ad ^4.4.0` pin onto nixpkgs' Certipy 5.1.0 - dies on import. Build it
# against Certipy 4.8.2 instead, private to certsync: the environments' own
# `certipy` CLI stays on 5.x.
{ lib, certsync, python3, fetchFromGitHub }:

let
  python = python3.override {
    self = python;
    packageOverrides = self: super: {
      certipy-ad = super.certipy-ad.overridePythonAttrs (old: {
        version = "4.8.2";
        src = fetchFromGitHub {
          owner = "ly4k";
          repo = "Certipy";
          tag = "4.8.2";
          hash = "sha256-Era5iNLJkZIRvN/p3BiD/eDiDQme24G65VSG97tuEOQ=";
        };
        # 4.8.2 pins pyasn1==0.4.8 and needs requests_ntlm (dropped in 5.x).
        pythonRelaxDeps = true;
        dependencies = old.dependencies ++ [ self.requests-ntlm ];
      });
    };
  };
in
certsync.override { python3 = python; }
