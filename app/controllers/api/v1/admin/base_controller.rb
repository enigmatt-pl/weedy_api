module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_user!
        before_action :ensure_super_admin!

        private

        def ensure_super_admin!
          head :forbidden unless current_user.super_admin?
        end
      end
    end
  end
end
