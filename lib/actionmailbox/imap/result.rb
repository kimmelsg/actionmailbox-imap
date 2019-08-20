module ActionMailbox
  module IMAP
    class Result
      def self.success(fields = {})
        result = create_result(fields.keys)
        result.new(success?: true, errors: [], **fields)
      end

      def self.failure(errors, fields = {})
        result = create_result(fields.keys)
        errors = Array.wrap(errors) unless errors.is_a?(Enumerable)
        result.new(success?: false, errors: errors, **fields)
      end

      private_class_method def self.create_result(fields)
        Struct.new(:success?, *fields, :errors, keyword_init: true)
      end
    end
  end
end
