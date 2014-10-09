class Place < ActiveRecord::Base
  class_attribute :geocoding_service
  self.geocoding_service = Geocoder

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: Kind.codes }
  validates :street, presence: true
  validates :zip_code, presence: true
  validates :city, presence: true

  validates :description, presence: true, on: :user_input
  validates :owner_name, presence: true, on: :user_input
  validates :owner_email, presence: true, on: :user_input

  geocoded_by :address

  before_save :set_coordinates, if: :geocoding_necessary?

  scope :displayable, -> { active.where(type: nil).where.not(longitude: nil, latitude: nil) }

  include AASM
  aasm column: 'state' do
    state :pending, initial: true
    state :active
    state :rejected

    event :accept do
      transitions from: :pending, to: :active
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end
  end

  def address
    [street, zip_code, city, country_code].compact.join(', ')
  end

  def duplicable_attributes
    attributes.except!('id',
                       'type',
                       'created_at',
                       'updated_at',
                       'owner_name',
                       'owner_email')
  end

  private

  def address_changed?
    (changed & ['street', 'zip_code', 'city', 'country_code']).any?
  end

  def geocoding_necessary?
    if new_record?
      missing_coordinates?
    else
      address_changed?
    end
  end

  def missing_coordinates?
    latitude.blank? || longitude.blank?
  end

  def set_coordinates
    self.latitude, self.longitude = geocoding_service.coordinates(address)
  end
end
