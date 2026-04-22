class StatusController < ApplicationController
  def index
    render json: { status: 'online', environment: Rails.env }
  end
end
