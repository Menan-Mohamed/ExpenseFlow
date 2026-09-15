class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 1.hour.from_now)
    payload[:exp] = exp.to_i
    payload[:jti] = SecureRandom.uuid
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end
end