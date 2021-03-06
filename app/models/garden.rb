class Garden < ActiveRecord::Base
  include Geocodable
  extend FriendlyId
  friendly_id :garden_slug, use: :slugged

  attr_accessible :name, :slug, :owner_id, :description, :active,
    :location, :latitude, :longitude, :area, :area_unit

  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'
  has_many :plantings, :order => 'created_at DESC', :dependent => :destroy
  has_many :crops, :through => :plantings

  # set up geocoding
  geocoded_by :location
  after_validation :geocode
  after_validation :empty_unwanted_geocodes

  default_scope order("lower(name) asc")
  scope :active, where(:active => true)
  scope :inactive, where(:active => false)

  validates :name,
    :format => {
      :with => /\S/
    }

  validates :area,
    :numericality => { :only_integer => false },
    :allow_nil => true

  AREA_UNITS_VALUES = {
    "square metres" => "square metre",
    "square feet" => "square foot",
    "hectares" => "hectare",
    "acres" => "acre"
  }
  validates :area_unit, :inclusion => { :in => AREA_UNITS_VALUES.values,
        :message => "%{value} is not a valid area unit" },
        :allow_nil => true,
        :allow_blank => true

  after_validation :cleanup_area

  def cleanup_area
    if area == 0
      self.area = nil
    end
    if area.blank?
      self.area_unit = nil
    end
  end

  def garden_slug
    "#{owner.login_name}-#{name}".downcase.gsub(' ', '-')
  end

  # featured plantings returns the most recent 4 plantings for a garden,
  # choosing them so that no crop is repeated.
  def featured_plantings
    unique_plantings = []
    seen_crops = []

    plantings.each do |p|
      if (! seen_crops.include?(p.crop))
        unique_plantings.push(p)
        seen_crops.push(p.crop)
      end
    end

    return unique_plantings[0..3]
  end

  def to_s
    name
  end

end
