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

  def current_user
    @current_user ||= authenticate_from_token
  end

  def authenticate_user!
    return if current_user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def authenticate_from_token
    token = request.headers['Authorization']&.split&.last
    return nil unless token

    decoded = JwtService.decode(token)
    return nil unless decoded

    User.find_by(id: decoded[:user_id])
  end

  def authenticate_super_admin!
    authenticate_user!
    return if performed? || current_user&.super_admin?

    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
