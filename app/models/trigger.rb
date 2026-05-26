class Trigger < ApplicationRecord
  belongs_to :merchant
  belongs_to :event
  belongs_to :campaign
end
