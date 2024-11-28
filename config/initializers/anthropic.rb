Anthropic.configure do |config|
  config.access_token = ENV.fetch("ANTHROPIC_API_KEY")
  config.anthropic_version = "2023-06-01"
end
