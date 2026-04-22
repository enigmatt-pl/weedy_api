# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  accepted_privacy_at    :datetime
#  accepted_terms_at      :datetime
#  allegro_auth_state     :string
#  approved               :boolean          default(FALSE)
#  avatar_url             :string
#  city                   :string
#  credits                :integer          default(0), not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  legal_version          :string
#  postcode               :string
#  province               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("user")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  include Rails.application.routes.url_helpers
  include StorageMaskable

  has_one_attached :avatar

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { user: 0, super_admin: 1 }

  has_many :dispensaries, dependent: :destroy

  validates :first_name, :last_name, presence: true
  validates :credits, numericality: { greater_than_or_equal_to: 0 }
  validates :accepted_terms_at, :accepted_privacy_at, :legal_version, presence: true, on: :create

  attr_reader :accept_terms, :accept_privacy, :accepted_terms, :accepted_privacy

  validates :accept_terms,
            acceptance: { accept: [true, 'true', '1'], message: 'must be accepted' },
            on: :create,
            unless: -> { accepted_terms_at.present? }
  validates :accept_privacy,
            acceptance: { accept: [true, 'true', '1'], message: 'must be accepted' },
            on: :create,
            unless: -> { accepted_privacy_at.present? }

  before_validation :set_acceptance_timestamps, on: :create

  def active_for_authentication?
    super && approved? && accepted_terms_at.present? && accepted_privacy_at.present?
  end

  def inactive_message
    if !approved?
      :not_approved
    elsif accepted_terms_at.blank?
      :terms_not_accepted
    elsif accepted_privacy_at.blank?
      :privacy_not_accepted
    else
      super
    end
  end

  def jwt_payload
    {
      user_id: id,
      role: role,
      approved: approved,
      accepted_terms_at: accepted_terms_at,
      accepted_privacy_at: accepted_privacy_at
    }
  end

  def accept_terms=(value)
    @accept_terms = value
    self.accepted_terms_at = Time.current if ActiveModel::Type::Boolean.new.cast(value)
  end

  def accept_privacy=(value)
    @accept_privacy = value
    self.accepted_privacy_at = Time.current if ActiveModel::Type::Boolean.new.cast(value)
  end

  def accepted_terms=(value)
    self.accepted_terms_at = value if value.present?
  end

  def accepted_privacy=(value)
    self.accepted_privacy_at = value if value.present?
  end

  def avatar_url_static
    masked_storage_url(avatar) || avatar_url
  end

  def credits?
    credits.positive?
  end

  private

  def format_postcode(pc)
    pc = pc.to_s.gsub(/\D/, '')
    return '00-001' if pc.length != 5

    "#{pc[0..1]}-#{pc[2..4]}"
  end

  def set_acceptance_timestamps
    self.accepted_terms_at ||= Time.current if ActiveModel::Type::Boolean.new.cast(accept_terms)
    self.accepted_privacy_at ||= Time.current if ActiveModel::Type::Boolean.new.cast(accept_privacy)
  end
end
