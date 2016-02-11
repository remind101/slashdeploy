module Slash
  # This defines the interface of the Slash::Handler, which is very similar to
  # the interface of Rack.
  class Handler
    # A handler is simply an object that responds to `call` and takes a hash as
    # the first argument. Slash's contract is that there will always be a
    # Slash::Command object in the `cmd` key of this hash.
    #
    # You can use this hash object to add your own arbitrary data in
    # middleware/decorators.
    def call(_env)
      fail NotImplementedError
    end
  end
end
