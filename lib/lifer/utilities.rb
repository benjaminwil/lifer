module Lifer::Utilities
  class << self
    def file_extension(path)
      path.to_s.downcase.match(/(?<=.)\..*/).to_s
    end

    def symbolize_keys(hash)
      symbolized_hash = {}

      hash.each do |key, value|
        symbolized_hash[(key.to_sym rescue key) || key] =
          value.is_a?(Hash) ? symbolize_keys(value) : value

        symbolize_keys(value) if value.is_a?(Hash)
      end

      symbolized_hash
    end
  end
end
