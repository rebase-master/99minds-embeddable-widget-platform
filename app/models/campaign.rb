class Campaign < ApplicationRecord
  acts_as_tenant :merchant

  validates :name, presence: true
  validates :event_type, presence: true
  validate :conditions_are_well_formed

  private

  def conditions_are_well_formed
    unless conditions.is_a?(Array)
      errors.add(:conditions, "must be an array")
      return
    end
    conditions.each_with_index { |c, i| validate_condition(c, i) }
  end

  def validate_condition(c, i)
    unless c.is_a?(Hash)
      errors.add(:conditions, "[#{i}] must be an object")
      return
    end

    op = c["op"]
    unless ConditionEvaluator::OPERATORS.include?(op)
      errors.add(:conditions, "[#{i}] uses unknown operator: #{op.inspect}")
      return
    end

    field = c["field"]
    unless field.is_a?(String) && !field.empty?
      errors.add(:conditions, "[#{i}] field must be a non-empty string")
    end

    if op != "exists" && c["value"].nil?
      errors.add(:conditions,
                 "[#{i}] op '#{op}' requires a non-null value (use 'exists' to test for presence)")
    end
  end
end
