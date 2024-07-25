final: prev: {
      gleam = prev.gleam.overrideAttrs(oldAttrs: rec {
        src = prev.fetchFromGitHub {
          owner = "gleam-lang";
          repo = "gleam";
          rev = "refs/tags/v1.3.2";
          hash = "sha256-ncb95NjBH/Nk4XP2QIq66TgY1F7UaOaRIEvZchdo5Kw=";
        };

        cargoDeps = oldAttrs.cargoDeps.overrideAttrs (prev.lib.const {
          name = "gleam-lang-vendor.tar.gz";
          inherit src;
          outputHash = "sha256-gxSM8r1JRtP8ZdXmMjPzTcp/+BX69JEbFl6tZgNwbf8=";
        });
    });
}
