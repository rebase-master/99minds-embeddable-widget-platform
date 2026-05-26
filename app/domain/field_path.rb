module FieldPath
  # Resolves a dotted path against a Hash. Allowlist: Hash + string keys only.
  # No `send`, no `dig` (avoids any method-dispatch surface).
  def self.resolve(hash, path)
    return nil unless hash.is_a?(Hash) && path.is_a?(String) && !path.empty?

    path.split(".").reduce(hash) do |current, key|
      return nil unless current.is_a?(Hash)
      current[key]
    end
  end
end
