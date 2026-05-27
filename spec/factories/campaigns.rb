FactoryBot.define do
  factory :campaign do
    # No merchant association — acts_as_tenant sets merchant_id from current_tenant.
    # Wrap creation with: ActsAsTenant.with_tenant(merchant) { create(:campaign) }
    sequence(:name) { |n| "Campaign #{n}" }
    active      { true }
    event_type  { "cart.updated" }
    conditions  { [] }
    render      { { "component" => "banner", "payload" => { "title" => "Test" } } }
  end
end
