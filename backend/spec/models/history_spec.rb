require 'rails_helper'

RSpec.describe History, type: :model do
  it "allows a history without a changer" do
    history = build(:history, changer: nil)

    expect(history).to be_valid
    expect(history.expense).to be_present
  end
end
