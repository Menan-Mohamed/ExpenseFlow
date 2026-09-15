require 'rails_helper'

RSpec.describe Team, type: :model do
  it "belongs to a manager" do
    manager = create(:user, role: :manager)
    team = build(:team, manager: manager)

    expect(team).to be_valid
    expect(team.manager).to eq(manager)
  end
end
