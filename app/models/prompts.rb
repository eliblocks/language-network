class Prompts
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def self.system
    <<~HEREDOC
      You are a bot that makes connections.
      People message you when they need something and whenever you feel you have enough information you let them know that you will be on the lookout for any users that can be of use to them.
      You need enough detail about something before you can make a search so you can find someone that is a good match.
      Once you have made a match the search is complete, until a user wants something else or requests another match.
      When people first message you they may not know much about you, so a short explanation may be appropriate.
      Users will view your messages on mobile so its best to avoid formatting like bullet points.
    HEREDOC
  end

  def self.welcome_message
    <<~HEREDOC
      Hello! I'm a bot that can connect you to people. Tell me a little about yourself and what you're looking for and I'll try to find someone relevant to you.
    HEREDOC
  end

  def self.comparison_format
    {
      "type": "json_schema",
      "json_schema": {
        "name": "best_match",
        "schema": {
          "type": "object",
          "properties": {
            "user_id": {
              "type": "integer",
              "description": "User id of the best match"
            },
            "explanation": {
              "type": "string",
              "description": "explanation for the given selection."
            }
          },
          "required": [
            "user_id",
            "explanation"
          ],
          "additionalProperties": false
        },
        "strict": true
      }
    }
  end

  def summary
    "Create a single message from the following conversation as if you were the user sending just a single message. Return only the message. \n\n#{user.formatted_messages}"
  end

  def comparison(user1, user2)
    <<~HEREDOC
      #{comparison_instructions}

      searching user
      #{user.formatted_messages}

      possible match
      #{user1.formatted_messages}

      possible match
      #{user2.formatted_messages}
    HEREDOC
  end

  def self.status_format
    {
      "type": "json_schema",
      "json_schema": {
        "name": "user_status",
        "schema": {
          "type": "object",
          "properties": {
            "status": {
              "type": "string",
              "description": "Indicates whether a user is active or inactive.",
              "enum": [
                "active",
                "inactive"
              ]
            },
            "explanation": {
              "type": "string",
              "description": "explanation for the given status."
            }
          },
          "required": [
            "status",
            "explanation"
          ],
          "additionalProperties": false
        },
        "strict": true
      }
    }
  end

  def status
    <<~HEREDOC
      We need to determine the current status of the conversation with the user below.
      Are we currently searching for matches for the user?

      active - We are currently searching for matches.
      inactive - We are not searching for matches at this moment.

      We need to align with the assistant in the conversation.
      So if we recently asked the user for more details, the status would not be active because we are still collecting information.
      And if we already found a match and have not started a new search, they would also not be active.

      #{user.formatted_messages}
    HEREDOC
  end

  def good_match(possible_match)
    <<~HEREDOC
      Based on the conversations with two separate users below, are they a good match for each other? Return yes or no.

      #{user.formatted_messages}

      #{possible_match.formatted_messages}
    HEREDOC
  end

  def introduction(matched_user)
    user.telegram_id ? telegram_introduction(matched_user) : instagram_introduction(matched_user)
  end

  private

  def comparison_instructions
    <<~HEREDOC
      We are now trying to find the best match for the searching user.
      Given the user and two other users along with their conversation histories,
      return the user id of the best match for the searching user.
    HEREDOC
  end

  def instagram_introduction(matched_user)
    <<~HEREDOC
      We are trying to craft a text message to introduce two users based on their conversations below.
      We need to return the actual message, not an explanation of the message, because the result of this prompt will be messaged to the user.
      This message will be sent to the user in middle of their current conversation so no need for a greeting.
      We do not want any kind of conclusion in the message.

      We are sending a message to #{user.intro_name} to let them know about #{matched_user.intro_name}.

      #{user.formatted_messages}


      #{matched_user.formatted_messages}
    HEREDOC
  end

  def telegram_introduction(matched_user)
    <<~HEREDOC
      We are trying to craft a text message to introduce two users based on their conversations below.
      We need to return the actual message, not an explanation of the message, because the result of this prompt will be sent to the user on the Telegram app.
      This message will be sent to the user in middle of their current conversation so no need for a greeting.
      Instead of referring to the user by name, just use their telegram link. Telegram will display the name in the a tag.

      We are sending a message to #{user.first_name} to let them know about #{matched_user.first_name}. #{matched_user.first_name}'s Telegram Link is #{matched_user.profile_link}


      #{user.formatted_messages}


      #{matched_user.formatted_messages}
    HEREDOC
  end
end
