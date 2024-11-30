require "rails_helper"

RSpec.describe "Matching", :vcr, type: :model do
  let (:searches) do
    [
      "Looking for a running buddy in Seattle's Capitol Hill area. I run 5-7 miles at a 9:30 pace, usually early mornings (6am) on weekdays. Training for a half marathon in June.",
      "Looking to join a fantasy football league in the Denver area. Experienced player, prefer in-person draft and weekly get-togethers to watch games.",
      "Native Spanish speaker seeking an English language exchange partner in Chicago. I'm available weekday evenings and can meet at local cafes. I work in marketing and would love to practice business English.",
      "Teaching beginner pottery classes from my home studio in Portland. Small groups, all materials provided. Thursday evenings or Sunday afternoons.",
      "Senior software engineer with 8 years experience offering mentorship in DS&A and system design. Experienced in Python and Java. Looking to help junior devs grow. Can commit to bi-weekly virtual sessions.",
      "Guitar/vocalist in Austin looking to form or join a band. Influenced by Arctic Monkeys, Interpol, and The Strokes. Seeking serious musicians for original music and regular practice. Have some songs written.",
      "Early bird runner in Capitol Hill seeking consistent running partner. I do 5-8 miles weekday mornings, typically 9-10 minute pace. Want to train for upcoming half marathons. Coffee after runs is a plus!",
      "Professional photographer available for wedding and event photography in Miami area. 10 years experience, full equipment setup, and backup photographer available.",
      "Drummer with 5+ years experience seeking bandmates in Austin. Into indie rock and post-punk. Have a practice space and recording equipment. Available for regular rehearsals and gigs.",
      "Junior developer (6 months experience) looking for a mentor in data structures and algorithms. Can meet virtually 2-3 times per month. Currently working with Python and trying to improve problem-solving skills.",
      "Looking for a Spanish conversation partner in Chicago's Loop area. I'm intermediate level and want to improve my business Spanish. I can help with English in exchange. Available after 6pm on weekdays.",
      "Seeking part-time dog walker in Brooklyn Heights for friendly golden retriever. Needed Monday-Wednesday afternoons, must be reliable and have references."
    ]
  end

  it "matches people up correctly" do
    users = []
    searches.each_index do |index|
      users << create(:user, id: index + 1)
    end

    users.each_with_index do |user, index|
      user.messages.create(role: "user", content: "Hello")
      user.messages.create(role: "assistant", content: Prompts.welcome_message)
      user.messages.create(role: "user", content: searches[index])
      user.respond
    end

    expect(Match.count).to eq(4)
  end
end
