# frozen_string_literal: true

module Uinit
  class Struct
    include Structure

    struct {} # rubocop:disable Lint/EmptyBlock: Empty block detected

    def initialize(**hsh)
      initialize_structure!(hsh)
    end
  end
end
