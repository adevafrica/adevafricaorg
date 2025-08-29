class MapLocation < ApplicationRecord
  belongs_to :project

  validates :latitude, :longitude, presence: true
  validates :latitude, numericality: { in: -90..90 }
  validates :longitude, numericality: { in: -180..180 }

  scope :within_bounds, ->(sw_lat, sw_lng, ne_lat, ne_lng) {
    where(
      latitude: sw_lat..ne_lat,
      longitude: sw_lng..ne_lng
    )
  }

  def coordinates
    [latitude, longitude]
  end

  def to_geojson
    {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [longitude, latitude]
      },
      properties: {
        id: id,
        project_id: project_id,
        title: title,
        description: description,
        project_title: project.title
      }
    }
  end

  # Calculate distance between two points using Haversine formula
  def distance_to(other_lat, other_lng)
    rad_per_deg = Math::PI / 180  # PI / 180
    rkm = 6371                    # Earth radius in kilometers
    rm = rkm * 1000               # Radius in meters

    dlat_rad = (other_lat - latitude) * rad_per_deg
    dlon_rad = (other_lng - longitude) * rad_per_deg

    lat1_rad = latitude * rad_per_deg
    lat2_rad = other_lat * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    rm * c # Distance in meters
  end
end

