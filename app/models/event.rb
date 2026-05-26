class Event < ApplicationRecord
  acts_as_tenant :merchant
end
