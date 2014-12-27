require 'macaroons/macaroons'
require 'macaroons/verifier'

class Macaroon < Macaroons::Macaroon
  class Verifier < Macaroons::Verifier; end
end
