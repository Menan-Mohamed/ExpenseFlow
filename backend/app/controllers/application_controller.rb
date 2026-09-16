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

  def filter_expenses(scope)
    requested_status = params[:status].presence || params[:state]
    scope = scope.where(state: requested_status) if Expense.states.key?(requested_status)
    scope = scope.where(category_id: params[:category].to_i) if params[:category].to_s.match?(Regexp.new("\\A\\d+\\z"))
    scope = scope.where(spent_date: params[:from_date]..) if valid_date?(params[:from_date])
    scope = scope.where(spent_date: ..params[:to_date]) if valid_date?(params[:to_date])

    sort_column = params[:sort] == "amount" ? :amount : :spent_date
    sort_column = :spent_date if params[:sort].blank? || params[:sort] == "date"
    direction = params[:direction] == "asc" ? :asc : :desc
    scope.order(sort_column => direction, created_at: :desc)
  end

  def valid_date?(value)
    Date.iso8601(value.to_s)
    true
  rescue ArgumentError
    false
  end
end