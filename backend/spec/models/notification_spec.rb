require 'rails_helper'

RSpec.describe Notification, type: :model do
  it "belongs to a user" do
    user = create(:user)
    notification = build(:notification, user: user)

    expect(notification).to be_valid
    expect(notification.user).to eq(user)
  end
end
