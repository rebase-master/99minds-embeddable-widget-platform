class Merchant < ApplicationRecord
  encrypts :hmac_secret

  has_many :events
  has_many :campaigns
  has_many :triggers
end
