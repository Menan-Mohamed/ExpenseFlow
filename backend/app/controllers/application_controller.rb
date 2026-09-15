class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_user, :current_jti, :current_exp

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    decoded = token && JsonWebToken.decode(token)

    if decoded.nil?
      render json: { error: "Unauthorized" }, status: :unauthorized and return
    end

    if JwtDenylist.revoked?(decoded[:jti])
      render json: { error: "Unauthorized" }, status: :unauthorized and return
    end

    @current_user = User.find_by(id: decoded[:user_id])

    if @current_user.nil? || !@current_user.active?
      render json: { error: "Unauthorized" }, status: :unauthorized and return
    end

    @current_jti = decoded[:jti]
    @current_exp = Time.at(decoded[:exp])
  end
end