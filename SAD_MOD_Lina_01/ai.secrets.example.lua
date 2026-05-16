-- Example AI secrets file for Mod_Lina.
-- Copy this content into ai.secrets.lua and set your real API key.

return {
    provider = "AzureOpenAI",
    endpoint = "https://your-resource.cognitiveservices.azure.com/",
    deployment = "gpt-5-mini",
    model = "gpt-5-mini",
    api_version = "2025-01-01-preview",
    key = "<your-api-key>",
}
