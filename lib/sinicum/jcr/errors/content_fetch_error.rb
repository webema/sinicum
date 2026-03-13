module Sinicum
  module Jcr
    module Errors
      class ContentFetchError < StandardError
        attr_reader :status

        def initialize(message = nil, status: nil)
          @status = status
          super(message)
        end
      end
    end
  end
end
