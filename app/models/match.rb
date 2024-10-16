class Match < ApplicationRecord
  belongs_to :searching_user, class_name: "User"
  belongs_to :matched_user, class_name: "User"
end
