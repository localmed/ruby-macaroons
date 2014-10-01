module Macaroons
  class Caveat
    def initialize(caveat_id, verification_id=nil, caveat_location=nil)
      @caveat_id = caveat_id
      @verification_id = verification_id
      @caveat_location = caveat_location
    end

    attr_accessor :caveat_id
    attr_accessor :verification_id
    attr_accessor :caveat_location

    def first_party?
      verification_id.nil?
    end

    def third_party?
      verification_id.nil? ? false : true
    end

    def to_json
      {'cid' => @caveat_id, 'vid' => @verification_id, 'cl' => @caveat_location}
    end

  end
end
