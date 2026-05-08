module Api
  module V1
    class DispensariesController < ApplicationController
      before_action :authenticate_user!, except: [:show]
      before_action :set_dispensary, only: [:show]
      before_action :set_owned_dispensary, only: [:update, :destroy, :publish, :unpublish]

      # Admin panel: returns the current user's own dispensaries.
      # Public search is handled by SearchesController.
      def index
        @dispensaries = if current_user.super_admin? && params[:user_id].present?
                          Dispensary.where(user_id: params[:user_id])
                        else
                          current_user.dispensaries
                        end

        @dispensaries = @dispensaries.with_attached_images
                                     .includes(:user)
                                     .order(created_at: :desc)
                                     .page(params[:page])
                                     .per(params[:per_page] || 10)
        render json: @dispensaries, meta: pagination_meta(@dispensaries)
      end

      def show
        render json: @dispensary
      end

      def create
        @dispensary = current_user.dispensaries.build(dispensary_params)
        attach_images(@dispensary, params[:dispensary][:images])

        if @dispensary.save
          render json: @dispensary, status: :created
        else
          render json: { errors: @dispensary.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        incoming_images = params.dig(:dispensary, :images).presence || params[:images].presence

        ActiveRecord::Base.transaction do
          if incoming_images.present?
            @dispensary.images.detach
            attach_images(@dispensary, incoming_images)
          end

          @dispensary.update!(dispensary_params.except(:images))
        end

        render json: @dispensary.reload, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Dispensary not found' }, status: :not_found
      end

      def publish
        if @dispensary.published!
          render json: {
            message: 'Punkt został opublikowany pomyślnie!',
            status: @dispensary.status
          }, status: :ok
        else
          render json: { error: 'Nie udało się opublikować punktu' }, status: :unprocessable_content
        end
      end

      def unpublish
        if @dispensary.draft!
          render json: {
            message: 'Publikacja została cofnięta.',
            status: @dispensary.status
          }, status: :ok
        else
          render json: { error: 'Nie udało się cofnąć publikacji' }, status: :unprocessable_content
        end
      end

      def destroy
        @dispensary.destroy!
        head :no_content
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

      def set_dispensary
        @dispensary = Dispensary.find(params[:id])

        # If not owner or admin, only show if published/active
        is_owner_or_admin = current_user && (@dispensary.user_id == current_user.id || current_user.super_admin?)
        is_visible = @dispensary.published? || @dispensary.active?
        render json: { error: 'Dispensary not found' }, status: :not_found unless is_owner_or_admin || is_visible
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Dispensary not found' }, status: :not_found
      end

      def set_owned_dispensary
        @dispensary = if current_user.super_admin?
                        Dispensary.find(params[:id])
                      else
                        current_user.dispensaries.find(params[:id])
                      end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Dispensary not found' }, status: :not_found
      end

      def dispensary_params
        params.require(:dispensary).permit(
          :title,
          :description,
          :estimated_price,
          :query_data,
          :city,
          :latitude,
          :longitude,
          :phone,
          :email,
          :website,
          :hours,
          :rating,
          :verification_id,
          :status,
          images: [],
          categories: []
        )
      end

      def attach_images(dispensary, images)
        return if images.blank?

        Array(images).each do |image|
          if image.respond_to?(:tempfile)
            checksum = Digest::MD5.file(image.tempfile.path).base64digest
            existing_blob = ActiveStorage::Blob.find_by(checksum: checksum)

            dispensary.images.attach(existing_blob || image)
          end
        rescue StandardError => e
          Rails.logger.error("DispensariesController: Attachment failed: #{e.message}")
        end
      end
    end
  end
end
