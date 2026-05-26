class Trigger < ApplicationRecord
  acts_as_tenant :merchant
  belongs_to :event
  belongs_to :campaign
end
