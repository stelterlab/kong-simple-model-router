local typedefs = require "kong.db.schema.typedefs"

return {
  name = "model-router",
  fields = {
    { config = {
        type = "record",
        fields = {
          -- Paths to intercept and route to upstream
          { paths = {
              type = "array",
              elements = { type = "string" },
              default = { "/v1/chat/completions" },
              required = false
          }},

          -- A map of "model_id" -> "upstream_host:port"
          -- e.g., "llama-3-8b" : "vllm-llama3:8000"
          { model_routing = {
              type = "map",
              keys = { type = "string" },
              values = { type = "string" },
              required = true
          }},
          { model_tokens = {
              type = "map",
              keys = { type = "string" },
              values = { type = "string" },
          }},
        },
    }},
  },
}
