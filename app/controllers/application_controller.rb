class ApplicationController < ActionController::API
  before_action :set_active_storage_url_options

  private

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = {
      protocol: request.protocol,
      host: request.host,
      port: request.port
    }
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split&.last

    return render json: { error: 'Unauthorized' }, status: :unauthorized unless token

    decoded = JwtService.decode(token)
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless decoded

    @current_user = User.find_by(id: decoded[:user_id])

    return if @current_user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def authenticate_super_admin!
    authenticate_user!
    return if performed? || current_user&.super_admin?

    render json: { error: 'Forbidden' }, status: :forbidden
  end

  attr_reader :current_user
end
