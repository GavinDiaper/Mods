ModLina = rawget(_G, "ModLina") or {}

local function now_ms()
    return (RealTime and RealTime()) or 0
end

local function trim_trailing_slash(text)
    if type(text) ~= "string" then
        return ""
    end
    while #text > 0 and text:sub(#text, #text) == "/" do
        text = text:sub(1, #text - 1)
    end
    return text
end

local function append_aina(message)
    local text = tostring(message or "AI not available")
    if string.find(text, "%(AINA%)", 1, true) then
        return text
    end
    return text .. " (AINA)"
end

local function get_json_module()
    local ok, json = pcall(require, "json")
    if ok and json then
        return json
    end
    return nil
end

local function json_encode(value)
    local json = get_json_module()
    if not json or not json.encode then
        return nil, "json_unavailable"
    end

    local ok, encoded = pcall(json.encode, value)
    if not ok then
        return nil, "json_encode_failed"
    end
    return encoded, nil
end

local function json_decode(text)
    local json = get_json_module()
    if not json or not json.decode then
        return nil, "json_unavailable"
    end

    local ok, decoded = pcall(json.decode, text)
    if not ok then
        return nil, "json_decode_failed"
    end
    return decoded, nil
end

local TOOL_NAME_TO_ACTION = {
    notify_player = "NotifyPlayer",
    report_threat = "ReportThreat",
    form_attack_squad = "FormAttackSquad",
    assign_attack_shrieker_nest = "AssignAttackShriekerNest",
    set_priority = "SetPriority",
}

local function build_tool_schemas()
    return {
        {
            type = "function",
            ["function"] = {
                name = "notify_player",
                description = "Send a concise in-game advisory message to the player.",
                parameters = {
                    type = "object",
                    additionalProperties = false,
                    required = { "message" },
                    properties = {
                        message = { type = "string", minLength = 1 },
                    },
                },
            },
        },
        {
            type = "function",
            ["function"] = {
                name = "report_threat",
                description = "Report current threat status using a strict label enum.",
                parameters = {
                    type = "object",
                    additionalProperties = false,
                    required = { "label" },
                    properties = {
                        label = {
                            type = "string",
                            enum = {
                                "Hostiles Lurking",
                                "Hostiles Nearby",
                                "Attacking now",
                                "Attacking in 10s",
                                "Attacking in 20s",
                                "Attacking in 30s",
                                "Attacking in 40s",
                                "Attacking in 50s",
                                "Attacking in 60s",
                                "Attacking in 70s",
                                "Nest Nearby",
                            },
                        },
                        enemy_count = { type = "number" },
                        eta_seconds = { type = "number" },
                    },
                },
            },
        },
        {
            type = "function",
            ["function"] = {
                name = "form_attack_squad",
                description = "Create a named survivor squad for combat response.",
                parameters = {
                    type = "object",
                    additionalProperties = false,
                    required = { "squad" },
                    properties = {
                        squad = {
                            type = "array",
                            minItems = 1,
                            items = { type = "string" },
                        },
                    },
                },
            },
        },
        {
            type = "function",
            ["function"] = {
                name = "assign_attack_shrieker_nest",
                description = "Assign one survivor to attack a specific shrieker nest id.",
                parameters = {
                    type = "object",
                    additionalProperties = false,
                    required = { "survivor", "nestId" },
                    properties = {
                        survivor = { type = "string", minLength = 1 },
                        nestId = { type = "string", minLength = 1 },
                    },
                },
            },
        },
        {
            type = "function",
            ["function"] = {
                name = "set_priority",
                description = "Mutating action. Set a survivor task priority level from 1 to 5.",
                parameters = {
                    type = "object",
                    additionalProperties = false,
                    required = { "survivor", "task", "level" },
                    properties = {
                        survivor = { type = "string", minLength = 1 },
                        task = { type = "string", minLength = 1 },
                        level = { type = "number", minimum = 1, maximum = 5 },
                    },
                },
            },
        },
    }
end

local function ensure_ai_windows()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return
    end

    local now = now_ms()
    if not ModLinaState.ai_hour_window_start or ModLinaState.ai_hour_window_start <= 0 then
        ModLinaState.ai_hour_window_start = now
    end
    if not ModLinaState.ai_day_window_start or ModLinaState.ai_day_window_start <= 0 then
        ModLinaState.ai_day_window_start = now
    end

    if (now - ModLinaState.ai_hour_window_start) >= 3600000 then
        ModLinaState.ai_hour_window_start = now
        ModLinaState.ai_calls_hour = 0
    end
    if (now - ModLinaState.ai_day_window_start) >= 86400000 then
        ModLinaState.ai_day_window_start = now
        ModLinaState.ai_calls_day = 0
    end
end

function ModLina.CanCallLLM()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return false, "AI state unavailable"
    end

    ensure_ai_windows()

    if not (ModLina.Config and ModLina.Config.IsAIEnabled and ModLina.Config.IsAIEnabled()) then
        return false, "AI cloud disabled"
    end

    local now = now_ms()
    local cooldown = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("cooldown_seconds")) or 120
    local max_hour = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("max_calls_per_hour")) or 8
    local max_day = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("max_calls_per_day")) or 25

    if ModLinaState.ai_last_call_time and (now - ModLinaState.ai_last_call_time) < (cooldown * 1000) then
        local remaining = cooldown - ((now - ModLinaState.ai_last_call_time) / 1000)
        return false, "Cooldown " .. tostring(remaining - (remaining % 1)) .. "s"
    end

    if max_hour > 0 and (ModLinaState.ai_calls_hour or 0) >= max_hour then
        return false, "Hourly cap reached"
    end
    if max_day > 0 and (ModLinaState.ai_calls_day or 0) >= max_day then
        return false, "Daily cap reached"
    end

    return true, nil
end

function ModLina.RecordLLMCall()
    if not rawget(_G, "ModLinaState") or not ModLinaState then
        return
    end

    ensure_ai_windows()
    ModLinaState.ai_last_call_time = now_ms()
    ModLinaState.ai_calls_total = (ModLinaState.ai_calls_total or 0) + 1
    ModLinaState.ai_calls_hour = (ModLinaState.ai_calls_hour or 0) + 1
    ModLinaState.ai_calls_day = (ModLinaState.ai_calls_day or 0) + 1
end

function ModLina.BuildLLMPrompt(user_request)
    if ModLina.UpdateState then
        ModLina.UpdateState()
    elseif rawget(_G, "print") then
        print("[ModLina:AI_LLM] UpdateState unavailable while building prompt; using current cached state")
    end

    local state = ModLina.State

    local prompt = {
        system = "You are Mod_Lina - Survivor Assistant, an AI copilot for Stranded: Alien Dawn.",
        instructions = "Call exactly one tool. Do not output free text. Prioritize survival and immediate threats.",
        tools = {
            "notify_player",
            "report_threat",
            "form_attack_squad",
            "assign_attack_shrieker_nest",
            "set_priority",
        },
        gamestate = state,
        request = user_request,
    }

    return prompt
end

function ModLina.BuildAzureChatRequest(user_request)
    local prompt = ModLina.BuildLLMPrompt(user_request)
    local api_key = ModLina.Config.GetAPICredential("key") or ""
    local endpoint = trim_trailing_slash(ModLina.Config.GetAPICredential("endpoint") or "")
    local deployment = ModLina.Config.GetAPICredential("deployment") or ModLina.Config.GetAPICredential("model") or "gpt-5-mini"
    local api_version = ModLina.Config.GetAPICredential("api_version") or "2024-04-01-preview"
    local timeout_seconds = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("timeout_seconds")) or 6

    if endpoint == "" then
        return nil, "missing_endpoint"
    end
    if deployment == "" then
        return nil, "missing_deployment"
    end
    if api_key == "" then
        return nil, "missing_api_key"
    end

    local request_body = {
        messages = {
            {
                role = "system",
                content = "You are Mod_Lina for Stranded: Alien Dawn. Call exactly one tool from the provided tool list. Do not output free text.",
            },
            {
                role = "user",
                content = "Player request: " .. tostring(prompt.request or "") .. "\nGame state: " .. tostring(ModLina.SerializeGameState() or "{}"),
            },
        },
        tools = build_tool_schemas(),
        tool_choice = "required",
        max_completion_tokens = 500,
    }

    local body_json, encode_err = json_encode(request_body)
    if not body_json then
        return nil, encode_err or "request_encode_failed"
    end

    local url = endpoint .. "/openai/deployments/" .. tostring(deployment) .. "/chat/completions?api-version=" .. tostring(api_version)
    local request = {
        provider = "AzureOpenAI",
        url = url,
        headers = {
            ["Content-Type"] = "application/json",
            ["api-key"] = api_key,
        },
        body = body_json,
        timeout_ms = math.max(1, tonumber(timeout_seconds) or 6) * 1000,
    }

    return request, nil
end

function ModLina.BuildLocalBridgeRequest(user_request)
    local prompt = ModLina.BuildLLMPrompt(user_request)
    local endpoint = trim_trailing_slash(ModLina.Config.GetAPICredential("endpoint") or "")
    local deployment = ModLina.Config.GetAPICredential("deployment") or ModLina.Config.GetAPICredential("model") or "gpt-5-mini"
    local api_version = ModLina.Config.GetAPICredential("api_version") or "2025-01-01-preview"
    local bridge_token = ModLina.Config.GetAPICredential("key") or ""
    local timeout_seconds = (ModLina.Config.GetAISetting and ModLina.Config.GetAISetting("timeout_seconds")) or 6

    if endpoint == "" then
        endpoint = "http://127.0.0.1:8787"
    end

    local request_body = {
        messages = {
            {
                role = "system",
                content = "You are Mod_Lina for Stranded: Alien Dawn. Call exactly one tool from the provided tool list. Do not output free text.",
            },
            {
                role = "user",
                content = "Player request: " .. tostring(prompt.request or "") .. "\nGame state: " .. tostring(ModLina.SerializeGameState() or "{}"),
            },
        },
        tools = build_tool_schemas(),
        tool_choice = "required",
        max_completion_tokens = 500,
        deployment = deployment,
        api_version = api_version,
    }

    local body_json, encode_err = json_encode(request_body)
    if not body_json then
        return nil, encode_err or "request_encode_failed"
    end

    local headers = {
        ["Content-Type"] = "application/json",
    }
    if bridge_token ~= "" then
        headers["x-lina-bridge-token"] = bridge_token
    end

    local request = {
        provider = "LocalBridge",
        url = endpoint .. "/v1/lina/chat",
        headers = headers,
        body = body_json,
        timeout_ms = math.max(1, tonumber(timeout_seconds) or 6) * 1000,
    }

    return request, nil
end

function ModLina.BuildProviderRequest(provider, user_request)
    if provider == "AzureOpenAI" then
        return ModLina.BuildAzureChatRequest(user_request)
    end
    if provider == "LocalBridge" then
        return ModLina.BuildLocalBridgeRequest(user_request)
    end
    return nil, "unsupported_provider"
end

function ModLina.ExtractActionFromAzureResponse(decoded)
    if type(decoded) ~= "table" then
        return nil, "invalid_response"
    end

    local choices = decoded.choices
    if type(choices) ~= "table" or #choices < 1 then
        return nil, "missing_choices"
    end

    local message = choices[1] and choices[1].message
    local tool_calls = message and message.tool_calls
    if type(tool_calls) ~= "table" or #tool_calls < 1 then
        return nil, "missing_tool_call"
    end

    local call = tool_calls[1]
    local fn = call["function"]
    if type(fn) ~= "table" then
        return nil, "missing_function"
    end

    local tool_name = fn.name
    local action = TOOL_NAME_TO_ACTION[tool_name]
    if not action then
        return nil, "unknown_tool_name"
    end

    local arguments = {}
    if type(fn.arguments) == "string" and fn.arguments ~= "" then
        local decoded_args, arg_err = json_decode(fn.arguments)
        if not decoded_args then
            return nil, arg_err or "invalid_tool_arguments"
        end
        arguments = decoded_args
    elseif type(fn.arguments) == "table" then
        arguments = fn.arguments
    end

    return {
        action = action,
        arguments = arguments,
        reasoning = nil,
    }, nil
end

function ModLina.PerformLLMRequest(request)
    if ModLina.LLMTransport and ModLina.LLMTransport.Send then
        return ModLina.LLMTransport.Send(request)
    end
    return nil, "transport_unavailable"
end

function ModLina.QueryLLM(user_request)
    if rawget(_G, "print") then
        print("[ModLina:AI_LLM] QueryLLM request received")
    end

    local allowed, reason = ModLina.CanCallLLM()
    if not allowed then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Cloud call blocked: " .. tostring(reason))
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = append_aina("Local mode: " .. tostring(reason))
            },
            reasoning = nil,
        }
    end

    local provider = ModLina.Config.GetAPICredential("provider") or ""
    if provider ~= "AzureOpenAI" and provider ~= "LocalBridge" then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Unsupported provider: " .. tostring(provider))
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = append_aina("Unsupported provider: " .. tostring(provider))
            },
            reasoning = nil,
        }
    end

    local request, request_err = ModLina.BuildProviderRequest(provider, user_request)
    if not request then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Request build failed: " .. tostring(request_err))
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = append_aina("AI request setup failed: " .. tostring(request_err))
            },
            reasoning = nil,
        }
    end

    local started = now_ms()
    ModLina.RecordLLMCall()
    if rawget(_G, "print") then
        print("[ModLina:AI_LLM] Sending AI request")
    end

    local raw_response, send_err = ModLina.PerformLLMRequest(request)
    local elapsed = now_ms() - started
    if rawget(_G, "ModLinaState") and ModLinaState then
        ModLinaState.ai_last_latency_ms = elapsed
    end

    if not raw_response then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Transport failure: " .. tostring(send_err))
        end
        if rawget(_G, "ModLinaState") and ModLinaState then
            ModLinaState.ai_last_error = tostring(send_err)
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = append_aina("AI transport error: " .. tostring(send_err))
            },
            reasoning = nil,
        }
    end

    local decoded, decode_err = nil, nil
    if type(raw_response) == "table" then
        decoded = raw_response
    elseif type(raw_response) == "string" then
        decoded, decode_err = json_decode(raw_response)
    else
        decode_err = "unexpected_response_type"
    end

    if not decoded then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Response decode failed: " .. tostring(decode_err))
        end
        if rawget(_G, "ModLinaState") and ModLinaState then
            ModLinaState.ai_last_error = tostring(decode_err)
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = append_aina("AI response parse failed: " .. tostring(decode_err))
            },
            reasoning = nil,
        }
    end

    local result, parse_err = ModLina.ExtractActionFromAzureResponse(decoded)
    if not result then
        if rawget(_G, "print") then
            print("[ModLina:AI_LLM] Tool-call parse failed: " .. tostring(parse_err))
        end
        if rawget(_G, "ModLinaState") and ModLinaState then
            ModLinaState.ai_last_error = tostring(parse_err)
        end
        return {
            action = "NotifyPlayer",
            arguments = {
                message = append_aina("AI output invalid: " .. tostring(parse_err))
            },
            reasoning = nil,
        }
    end

    if ModLina.ValidateLLMAction then
        local ok, validation_reason = ModLina.ValidateLLMAction(result.action, result.arguments or {})
        if not ok then
            if rawget(_G, "print") then
                print("[ModLina:AI_LLM] Action validation rejected: " .. tostring(validation_reason))
            end
            return {
                action = "NotifyPlayer",
                arguments = {
                    message = append_aina("AI output rejected: " .. tostring(validation_reason))
                },
                reasoning = nil,
            }
        end
    end

    if rawget(_G, "ModLinaState") and ModLinaState then
        ModLinaState.ai_last_error = nil
    end
    if rawget(_G, "print") then
        print("[ModLina:AI_LLM] AI action accepted: " .. tostring(result.action))
    end
    return result
end

function ModLina.SerializeGameState()
    -- Helper to convert ModLina.State to JSON-serializable format
    -- This will be needed when actually calling the LLM API
    local encoded, _ = json_encode(ModLina.State)
    if encoded then
        return encoded
    end
    return tostring(ModLina.State)
end

function ModLina.ParseLLMResponse(response_text)
    -- Helper to parse LLM JSON response
    -- This will be needed when actually calling the LLM API
    local decoded, _ = json_decode(response_text)
    return decoded
end
