module Api
  module V1
    class DispensariesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_dispensary, only: [:show, :update, :destroy, :publish]

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
        # For now, keeping the service call but renaming the class if needed later
        # result = AllegroService.new(current_user, @dispensary).call
        # Since this is a rebrand to Weedy (dispensaries), we might not use Allegro.
        # But for the migration, I'll just comment it out or keep it generic.
        render json: { message: 'Publishing logic to be updated for dispensaries' }, status: :ok
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
        @dispensary = if current_user.super_admin?
                        Dispensary.find(params[:id])
                      else
                        current_user.dispensaries.find(params[:id])
                      end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Dispensary not found' }, status: :not_found
      end

      def dispensary_params
        params.require(:dispensary).permit(:title, :description, :estimated_price, :status, :query_data, :verification_id,
                                           :external_product_id, :category_id, :reasoning, images: [], image_urls: [])
      end

      def attach_images(dispensary, images)
        return if images.blank?

        Array(images).each do |image|
          if image.respond_to?(:tempfile)
            checksum = Digest::MD5.file(image.tempfile.path).base64digest
            existing_blob = ActiveStorage::Blob.find_by(checksum: checksum)

            if existing_blob
              dispensary.images.attach(existing_blob)
            else
              dispensary.images.attach(image)
            end
          end
        rescue StandardError => e
          Rails.logger.error("DispensariesController: Attachment failed: #{e.message}")
        end
      end
    end
  end
end
