module ConditionEvaluator
  OPERATORS = %w[eq neq gt gte lt lte in exists].freeze

  # Returns true if every condition matches the event payload. Implicit AND.
  def self.match?(conditions, event_data)
    return false unless conditions.is_a?(Array)
    conditions.all? { |c| evaluate(c, event_data) }
  end

  def self.evaluate(condition, data)
    return false unless condition.is_a?(Hash)
    actual = FieldPath.resolve(data, condition["field"])
    value = condition["value"]

    case condition["op"]
    when "eq"     then actual == value
    when "neq"    then actual != value
    when "gt"     then numeric_compare(actual, value) { |a, v| a > v }
    when "gte"    then numeric_compare(actual, value) { |a, v| a >= v }
    when "lt"     then numeric_compare(actual, value) { |a, v| a < v }
    when "lte"    then numeric_compare(actual, value) { |a, v| a <= v }
    when "in"     then value.is_a?(Array) && value.include?(actual)
    when "exists" then !actual.nil?
    else false
    end
  end

  def self.numeric_compare(actual, value)
    return false unless actual.is_a?(Numeric) && value.is_a?(Numeric)
    yield(actual, value)
  end
  private_class_method :numeric_compare
end
