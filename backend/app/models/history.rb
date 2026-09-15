class History < ApplicationRecord
  belongs_to :expense
  belongs_to :changer, class_name: "User", optional: true
end
