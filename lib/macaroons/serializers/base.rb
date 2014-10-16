module Macaroons
  class BaseSerializer

    def serialize(macaroon)
      raise NotImplementedError
    end

    def deserialize(serialized)
      raise NotImplementedError
    end

  end
end
