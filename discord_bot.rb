# frozen_string_literal: true

require 'dotenv/load'
require 'discordrb'
require_relative './config/environment'


bot = Discordrb::Bot.new(
  token: ENV["DISCORD_TOKEN"],
  intents: [ :direct_messages ]
)

# This method call adds an event handler that will be called on any message that exactly contains the string "Ping!".
# The code inside it will be executed, and a "Pong!" response will be sent to the channel.
bot.message do |event|
  if event.channel.private?
    discord_id = event.user.id
    discord_username = event.user.username
    content = event.content

    user = User.find_or_initialize_by(discord_id:)
    user.discord_username = discord_username
    user.email = "#{discord_id}@example.com"
    user.password = SecureRandom.hex

    user.save!

    user.messages.create(role: "user", content:)

    user.respond

    pp event
  end
end

bot.run
