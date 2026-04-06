# Kong API Gateway model-router plugin

This a very simple model-router plugin for the [Kong API Gateway](https://github.com/Kong/kong).

Normally I use LiteLLM just to manage different local vLLM instances beyond one endpoint. But after the last [supply chain attack](https://github.com/BerriAI/litellm/issues/24518) (March 2026) I tought about finding an alternative as I normally only need to route between two or more instances for testing.

As I played around with Kong already in the past, I looked into it again for this problem. Kong offers a AI Proxy plugin, but that does not suit my needs. I just want to be able to route to different endpoint based upon a model ID specified in the body of a request.

So this is the result of some tests. I used also the opportunity over the easter weekend to test my tasks against different LLMs. So yes - this code contains large portions of AI generated code, too.

It might be useful to someone else out there.

It should work for every endpoint that serves an OpenAI compatible API - so it should work also for SGLang, llama.cpp & Co.

# Requirements

To run this example you need:

* a system with docker and 
* one or more GPUs (or multiple system with GPUs for your vLLM instances)
* a HF token for the .env for vLLM instances (recommended for gated models and better download speeds)

## Setup

```
git clone https://github.com/stelterlab/model-router-simple.git
cd model-router-simple
cd vllm
copy env_example .env
```

Adjust your .env and - if desired - adjust the vllm/docker-compose.yml to suit your needs.

NOTE: Check the versions of the container images used. As vLLM is rapidly evolving v0.19.0 might be already outdated. I used a Blackwell GPU - therefore I used the cu130 image. Feel free to adjust.

This setup is intended for testing on a single machine. So adjust the kong/kong.yml

```
              model_routing:
                "smol3-3b": "192.168.0.123:8101"
                "qwen35-tiny": "192.168.0.123:8102"
              model_tokens:
                "smol3-3b": "sk-secret"
                "qwen35-tiny": "sk-secret"

```

I choose this models, because they are small. Replace "smol3-3b" with model alias / served model name. And 192.168.0.123:8101 with your host IP and port on which vLLM is running.

NOTE: When you run all vLLM instances and your gateway on the same machine (eg. DGX Spark or a beast with multiple RTX PRO 6000) you can not use 127.0.0.1 as routing target, because the Kong is running in a different container (and network).

After adjusting your config, just run:

```
cd vllm
docker compose up -d
cd ../kong
docker compose up -d

curl -s http://localhost:8000/v1/models|jq -r .
{
  "data": [
    {
      "created": 1775490780,
      "owned_by": "vllm",
      "id": "qwen35-tiny",
      "object": "model"
    },
    {
      "created": 1775490780,
      "owned_by": "vllm",
      "id": "smol3-3b",
      "object": "model"
    }
  ],
  "object": "list"
}
```

If don't want to use my docker-compose.yml, copy the plugins/model-router directory to the plugins directory of your (already used) Kong instance. See also:

Offical Documentation [Installation and distribution of custom plugins](https://developer.konghq.com/custom-plugins/installation-and-distribution/)

Feedback is welcome.

## Contributors

* VS Coder Insider
* Zed
* MiniMaxAI/MiniMax-M2.5
* google/gemma-4-26B-A4B-it
* Gemini 3.1
* GPT-5.3-Codex
* Chuck vom Brunnen (the guy on the right side of my profile picture)
