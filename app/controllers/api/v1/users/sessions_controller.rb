module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        respond_to :json

        def create
          user = User.find_by(email: params[:user][:email])
          if user&.valid_password?(params[:user][:password])
            if user.active_for_authentication?
              token = JwtService.encode(user.jwt_payload)
              render json: {
                token: token,
                user: user_as_json(user)
              }, status: :ok
            else
              render json: { error: I18n.t("devise.failure.#{user.inactive_message}") }, status: :forbidden
            end
          else
            render json: { error: 'Invalid credentials' }, status: :unauthorized
          end
        end

        private

        def user_as_json(user)
          {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            avatar_url: user.avatar_url_static,
            role: user.role,
            approved: user.approved,
            city: user.city,
            postcode: user.postcode,
            province: user.province
          }
        end
      end
    end
  end
end
