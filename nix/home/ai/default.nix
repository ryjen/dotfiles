{ ... }:

{
  imports = [
    ./plano.nix
    ./model-router.nix
  ];

  # This file only aggregates opt-in AI client configuration modules.
  # Enable them from a host/user profile with:
  #
  #   ryjen.ai.plano.enable = true;
  #   ryjen.ai.model-router.enable = true;
}
