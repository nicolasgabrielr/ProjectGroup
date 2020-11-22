class Validation_model < StandardError
    attr_reader : errors

    def initialize(msg = "datos incorrectos", errors)
      super(msg)
      @errors = errors
    end
end