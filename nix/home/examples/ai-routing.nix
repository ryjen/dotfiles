{ ... }:

{
  imports = [
    ../ai
  ];

  ryjen.ai.plano = {
    enable = true;

    # Dubnium should provide this OpenAI-compatible local endpoint via vLLM
    # or Ollama. This module only configures the user-facing client side.
    localBaseUrl = "http://127.0.0.1:8000/v1";
    listenerAddress = "127.0.0.1";
    listenerPort = 12000;
  };

  ryjen.ai.model-router = {
    enable = true;
    profileName = "local-first-dev";
  };
}
