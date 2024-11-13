class Prompts
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def welcome_message
    <<~HEREDOC
      Hello! I'm a bot that can connect you to people. Tell me a little about what you're looking for and I'll try to find someone relevant to you.
    HEREDOC
  end

  def summary
    "Summarize the interest of the user with the following conversation:\n\n#{user.formatted_messages}"
  end

  def comparison(user1, user2)
    <<~HEREDOC
      #{platform_description}

      #{comparison_instructions}

      searching user
      #{user.formatted_messages}

      possible match
      #{user1.formatted_messages}

      possible match
      #{user2.formatted_messages}
    HEREDOC
  end

  def active
    <<~HEREDOC
      #{platform_description}

      Based on the conversation below which status should we set the user to?

      active - We should be actively searching for matches.
      inactive - We should not be searching for matches at this moment.

      respond with only one word, active or inactive.

      #{user.formatted_messages}
    HEREDOC
  end

  def continue_conversation
    <<~HEREDOC
      #{platform_description}

      Guide the user towards providing sufficient information that could be used to match them with other users.
    HEREDOC
  end

  def good_match(possible_match)
    <<~HEREDOC
      #{platform_description}

      Based on the conversations with two separate users below, are they a good match for each other? Return yes or no.

      #{user.formatted_messages}

      #{possible_match.formatted_messages}
    HEREDOC
  end

  def introduction(matched_user)
    user.telegram_id ? telegram_introduction(matched_user) : instagram_introduction(matched_user)
  end

  private

  def platform_description
    <<~HEREDOC
      You are a bot that makes connections.
      People message you when they need something and whenever you feel you have enough information you let them know that you will be on the lookout for any users that can be of use to them.
      You need enough details about something before you can make a search so you can find someone that is a good match.

      However do not ask for exessive detail, if the user provides details in their first message dont ask for more unless needed.
    HEREDOC
  end

  def comparison_instructions
    <<~HEREDOC
      We are now trying to find the best match for the searching user.
      Given the user and two other users along with their conversation histores,
      return the user id of the best match for the searching user. return only a user_id.
    HEREDOC
  end

  def instagram_introduction(matched_user)
    <<~HEREDOC
      We are trying to craft a text message to introduce two users based on their conversations below.
      We need to return the actual message, not an explanation of the message, because the result of this prompt will be messaged to the user.
      This message will be sent to the user in middle of their current conversation so no need for a greeting.
      Don't provide any information on contacting the user.

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
