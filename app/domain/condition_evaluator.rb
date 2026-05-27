module ConditionEvaluator
  OPERATORS = %w[eq gt gte lt lte exists].freeze

  def self.match?(conditions, event_data)
    return false unless conditions.is_a?(Array)
    conditions.all? { |c| evaluate(c, event_data) }
  end

  def self.evaluate(condition, data)
    return false unless condition.is_a?(Hash)
    actual = resolve_field(data, condition["field"])
    value = condition["value"]

    case condition["op"]
    when "eq"     then actual == value
    when "gt"     then numeric_compare(actual, value) { |a, v| a > v }
    when "gte"    then numeric_compare(actual, value) { |a, v| a >= v }
    when "lt"     then numeric_compare(actual, value) { |a, v| a < v }
    when "lte"    then numeric_compare(actual, value) { |a, v| a <= v }
    when "exists" then !actual.nil?
    else false
    end
  end

  # Allowlisted dotted-path resolver. Hash + String keys only — no `send`/`eval`/`dig`.
  def self.resolve_field(hash, path)
    return nil unless hash.is_a?(Hash) && path.is_a?(String) && !path.empty?

    path.split(".").reduce(hash) do |current, key|
      return nil unless current.is_a?(Hash)
      current[key]
    end
  end
  private_class_method :resolve_field

  def self.numeric_compare(actual, value)
    return false unless actual.is_a?(Numeric) && value.is_a?(Numeric)
    yield(actual, value)
  end
  private_class_method :numeric_compare
end
