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
    HEREDOC
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
      #{comparison_instructions}

      searching user
      #{user.formatted_messages}

      possible match
      #{user1.formatted_messages}

      possible match
      #{user2.formatted_messages}
    HEREDOC
  end

  # def active
  #   <<~HEREDOC
  #     We need to determine if we should be matching this user. 
  #     We need to know if we have enough information at this point.
  #     We also want to make sure our decision aligns with what the assistant has said in the conversation.

  #     Based on the conversation below which status should we set the user to?

  #     active - We should be actively searching for matches.
  #     inactive - We should not be searching for matches at this moment.

  #     respond with only one word, active or inactive.

  #     #{user.formatted_messages}
  #   HEREDOC
  # end


  # def active
  #   <<~HEREDOC
  #     We need to determine the current status of the conversation with the user below.


  #     respond with only one word, active or inactive.

  #     active - We should be actively searching for matches.
  #     inactive - We should not be searching for matches at this moment.

  #     #{user.formatted_messages}
  #   HEREDOC
  # end

  def active
    <<~HEREDOC
      We need to determine the current status of the conversation with the user below.
      Are we currently searching for matches for the user?

      respond with only one word, active or inactive.

      active - We should be actively searching for matches.
      inactive - We should not be searching for matches at this moment.

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
      return the user id of the best match for the searching user. return only a user_id.
      Even if both users are a poor match, return the best possible option.


      ===========================

      Example response: 521
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
