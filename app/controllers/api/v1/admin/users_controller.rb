module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          @users = User.order(created_at: :desc)
          if params[:query].present?
            @users = @users.where('email ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q',
                                  q: "%#{params[:query]}%")
          end

          @users = @users.page(params[:page]).per(params[:per_page] || 20)

          render json: @users, meta: pagination_meta(@users), adapter: :json
        end

        def approve
          @user = User.find(params[:id])
          if @user.update(approved: true)
            render json: { message: 'User approved' }, status: :ok
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
          end
        end

        def unapprove
          @user = User.find(params[:id])
          if @user.update(approved: false)
            render json: { message: 'User unapproved' }, status: :ok
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
          end
        end

        def update_credits
          @user = User.find(params[:id])
          # Unified credits permit for root or wrapped parameters
          new_credits = params[:credits] || (params[:user] && params[:user][:credits])

          if @user.update(credits: new_credits)
            render json: { message: 'Credits updated', credits: @user.credits }, status: :ok
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
          end
        end

        def destroy
          @user = User.find(params[:id])
          @user.destroy!
          head :no_content
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'User not found' }, status: :not_found
        end

        def full_delete
          @user = User.find(params[:id])
          @user.listings.each { |l| l.images.purge if l.respond_to?(:images) }
          @user.avatar.purge if @user.avatar.attached?
          @user.destroy!
          head :no_content
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'User not found' }, status: :not_found
        end

        private

        def pagination_meta(object)
          {
            current_page: object.current_page,
            next_page: object.next_page,
            prev_page: object.prev_page,
            total_pages: object.total_pages,
            total_count: object.total_count
          }
        end
      end
    end
  end
end
