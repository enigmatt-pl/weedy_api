module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json
        before_action :authenticate_user!, only: [:update, :avatar]
        skip_before_action :authenticate_scope!, only: [:update, :avatar]

        def create
          build_resource(sign_up_params)
          if resource.save
            token = JwtService.encode(user_id: resource.id)
            render json: {
              token: token,
              user: {
                id: resource.id,
                email: resource.email,
                first_name: resource.first_name,
                last_name: resource.last_name,
                avatar_url: resource.avatar_url_static,
                city: resource.city,
                postcode: resource.postcode,
                province: resource.province
              }
            }, status: :created
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_content
          end
        end

        def update
          @user = current_user
          if @user.update(account_update_params)
            render json: {
              user: {
                id: @user.id,
                email: @user.email,
                first_name: @user.first_name,
                last_name: @user.last_name,
                avatar_url: @user.avatar_url_static,
                city: @user.city,
                postcode: @user.postcode,
                province: @user.province
              }
            }, status: :ok
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
          end
        end

        def avatar
          @user = current_user
          if params[:avatar].present?
            unless params[:avatar].is_a?(ActionDispatch::Http::UploadedFile)
              return render json: { error: 'Invalid file format received' }, status: :unprocessable_content
            end

            @user.avatar.attach(params[:avatar])
            # Also update avatar_url string field for convenience if needed,
            # but we prefer using avatar_url_static helper which prioritizes attachment
            if @user.save
              @user.reload
              url = @user.avatar_url_static
              render json: {
                user: {
                  id: @user.id,
                  email: @user.email,
                  first_name: @user.first_name,
                  last_name: @user.last_name,
                  avatar_url: url,
                  city: @user.city,
                  postcode: @user.postcode,
                  province: @user.province
                },
                avatar_url: url
              }, status: :ok
            else
              render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
            end
          else
            render json: { error: 'No avatar file provided' }, status: :unprocessable_content
          end
        end

        private

        def sign_up_params
          params.require(:user).permit(
            :email, :password, :password_confirmation, :first_name, :last_name,
            :city, :postcode, :province, :accept_terms, :accept_privacy,
            :accepted_terms, :accepted_privacy, :legal_version
          ).reverse_merge(legal_version: 'v1-beta')
        end

        def account_update_params
          params.require(:user).permit(
            :first_name, :last_name, :city, :postcode, :province
          )
        end
      end
    end
  end
end
