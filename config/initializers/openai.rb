OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_SECRET")
  config.log_errors = true # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production.
end
