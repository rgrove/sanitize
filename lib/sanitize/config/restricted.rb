# frozen_string_literal: true

class Sanitize
  module Config
    RESTRICTED = freeze_config(
      elements: %w[b em i strong u]
    )
  end
end
