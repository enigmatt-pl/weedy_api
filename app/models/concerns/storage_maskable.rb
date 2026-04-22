module StorageMaskable
  extend ActiveSupport::Concern

  def masked_storage_url(attachment)
    return nil if attachment.nil?

    # attachment can be an association (has_one_attached) or a single attachment (from has_many_attached.map)
    # The association responds to .attached?, but the individual attachment does not.
    return nil if attachment.respond_to?(:attached?) && !attachment.attached?

    host = ENV.fetch('APP_HOST') { ENV.fetch('RENDER_EXTERNAL_HOSTNAME', 'localhost:3000') }
    options = ActiveStorage::Current.url_options || { host: host, protocol: Rails.env.production? ? 'https' : 'http' }

    Rails.application.routes.url_helpers.custom_storage_proxy_url(
      attachment.signed_id,
      attachment.filename,
      options
    )
  rescue StandardError => e
    Rails.logger.error("StorageMaskable Failed: #{e.message}")
    nil
  end
end
