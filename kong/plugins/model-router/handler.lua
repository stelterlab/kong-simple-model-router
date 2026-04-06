local cjson = require "cjson.safe"

local ModelRouter = {
  PRIORITY = 1000, -- Runs early in the access phase
  VERSION = "1.0.0",
}

-- Approximates Kong instance start time for this worker process.
local INSTANCE_STARTED_AT = ngx.time()

local function integer_or_nil(value)
  if type(value) == "number" then
    return math.floor(value)
  end

  if type(value) == "string" then
    local n = tonumber(value)
    if n then
      return math.floor(n)
    end
  end

  return nil
end

function ModelRouter:access(conf)
  -- EMULATE /v1/models ENDPOINT
  local path = kong.request.get_path()
  if path:match("/v1/models$") then
    local models_list = {}
    -- Dynamically generate the list based on the plugin config
    for model_id, _ in pairs(conf.model_routing) do
      table.insert(models_list, {
        id = model_id,
        object = "model",
        created = INSTANCE_STARTED_AT,
        owned_by = "vllm"
      })
    end

    return kong.response.exit(200, {
      object = "list",
      data = models_list
    })
  end

  -- ROUTE REQUESTS BASED ON MODEL ID
  -- Check if the request path matches any of the configured paths
  local matched_path = nil
  for _, pattern in ipairs(conf.paths) do
    if path:match(pattern .. "$") then
      matched_path = pattern
      break
    end
  end

  if matched_path then
    -- Kong automatically parses JSON bodies if Content-Type is application/json
    local body, body_err = kong.request.get_body()
    if body_err then
      return kong.response.exit(400, { error = "Invalid request body: " .. body_err })
    end

    if not body or type(body.model) ~= "string" then
      return kong.response.exit(400, { error = "Missing 'model' field in JSON body" })
    end

    local target = conf.model_routing[body.model]
    if not target then
      return kong.response.exit(404, { error = "Model '" .. body.model .. "' not supported by gateway" })
    end

    -- Extract host and port from the target string (e.g., "vllm-llama3:8000")
    local host, port = target:match("([^:]+):(%d+)")
    if not host then
      host = target
      port = 80 -- Default fallback
    end

    -- Dynamically override the upstream target for this specific request
    kong.service.set_target(host, tonumber(port))

    -- Add backend API token if configured
    local model_token = conf.model_tokens and conf.model_tokens[body.model]
    if model_token then
      kong.service.request.set_header("Authorization", "Bearer " .. model_token)
    end

    -- Preserve the original client path (including /v1) for the upstream service.
    kong.service.request.set_path(path)
  end
end

return ModelRouter
