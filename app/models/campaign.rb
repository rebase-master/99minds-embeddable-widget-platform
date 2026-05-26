class Campaign < ApplicationRecord
  acts_as_tenant :merchant

  validates :name, presence: true
  validates :event_type, presence: true
  validate :conditions_have_known_operators

  private

  def conditions_have_known_operators
    return unless conditions.is_a?(Array)
    conditions.each_with_index do |c, i|
      op = c.is_a?(Hash) ? c["op"] : nil
      unless ConditionEvaluator::OPERATORS.include?(op)
        errors.add(:conditions, "[#{i}] uses unknown operator: #{op.inspect}")
      end
    end
  end
end
