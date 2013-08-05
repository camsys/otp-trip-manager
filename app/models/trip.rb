class Trip < ActiveRecord::Base
  attr_accessor :trip_date, :trip_time

  # before_validation :set_places
  # validates :from_place_id, :to_place_id, :presence => {:message => I18n.translate(:invalid_location)}
  validate :validate_date_and_time
  validate :datetime_cannot_be_before_now
  attr_accessible :name, :owner, :trip_datetime, :trip_date, :trip_time, :arrive_depart, :places_attributes,
  :from_place, :to_place, :owner
  attr_accessor :from_place, :to_place
  belongs_to :owner, foreign_key: 'user_id', class_name: User
  # has_one :from_place, foreign_key: 'from_place_id', class_name: TripPlace
  # has_one :to_place, foreign_key: 'to_place_id', class_name: TripPlace
  has_many :places, class_name: TripPlace
  has_many :itineraries
  has_many :valid_itineraries, conditions: 'status=200', class_name: 'Itinerary'

  accepts_nested_attributes_for :places

  def has_valid_itineraries?
    not valid_itineraries.empty?
  end

  def validate_date_and_time
    good_date = true
    good_time = true
    begin
      Date.strptime(self.trip_date, "%m/%d/%Y")
    rescue
      errors.add(:trip_date, I18n.translate(:date_wrong_format))
      good_date = false
    end

    begin
      Time.strptime(trip_time, "%H:%M %p")
    rescue Exception
      errors.add(:trip_time, I18n.translate(:time_wrong_format))
      good_time = false
    end

    return false unless good_date && good_time

    if !write_trip_datetime
      errors.add(:trip_date, I18n.translate(:date_wrong_format))
    end
    true
  end

  def write_trip_datetime
    begin
      self.trip_datetime = DateTime.strptime([trip_date, trip_time, DateTime.current.zone].join(' '),
        '%m/%d/%Y %H:%M %p %z')
    rescue Exception => e
      return false
    end
    true
  end

  def datetime_cannot_be_before_now
    return true if trip_datetime.nil?
    if trip_datetime < Date.today
      errors.add(:trip_date, I18n.translate(:trips_cannot_be_entered_for_days))
      return false
    elsif trip_datetime < Time.current
      errors.add(:trip_time, I18n.translate(:trips_cannot_be_entered_for_times))
      return false
    end
    true
  end

  def create_itineraries
    self.create_fixed_route_itineraries
    self.create_taxi_itineraries
    self.create_paratransit_itineraries
  end

  # TODO refactor following 3 methods
  def create_fixed_route_itineraries
    tp = TripPlanner.new
    arriveBy = arrive_depart.index("arrive_by") ? "true" : "false"
    result, response = tp.get_fixed_itineraries([self.places[0].lat, self.places[0].lon],[self.places[1].lat, self.places[1].lon], self.trip_datetime.in_time_zone, arriveBy)
    if result
      tp.convert_itineraries(response).each do |itinerary|
        self.itineraries << Itinerary.new(itinerary)
      end
    else
      self.itineraries << Itinerary.new('status'=>response['id'], 'message'=>response['msg'])
    end
  end

  def create_taxi_itineraries
    tp = TripPlanner.new
    result, response = tp.get_taxi_itineraries([self.to_place.lat, self.to_place.lon],[self.from_place.lat, self.from_place.lon], self.trip_datetime.in_time_zone)
    if result
      itinerary = tp.convert_taxi_itineraries(response)
      self.itineraries << Itinerary.new(itinerary)
    else
      self.itineraries << Itinerary.new('status'=>500, 'message'=>response)
    end
  end

  def create_paratransit_itineraries
    #TODO: This is just a place holder that currently returns demo data only.
    tp = TripPlanner.new
    result, response = tp.get_paratransit_itineraries([self.to_place.lat, self.to_place.lon],[self.from_place.lat, self.from_place.lon], self.trip_datetime.in_time_zone)
    if result
      itinerary = tp.convert_paratransit_itineraries(response)
      self.itineraries << Itinerary.new(itinerary)
    else
      self.itineraries << Itinerary.new('status'=>500, 'message'=>response)
    end
  end

  def set_places
    #TODO:  These values need to come from the combobox field
    to_place_id = 52
    from_place_id = 53
    nongeocoded_address = "100 14th Street, Atlanta, GA"

    if to_place_id #Here is where we test that an ID is present.
      self.to_place_id = to_place_id
    else
      to_place = Place.new('nongeocoded_address'=>nongeocoded_address)
      to_place.name = nongeocoded_address
      to_place.owner = self.owner
      to_place.save()
      self.to_place_id = to_place.id
    end

    if from_place_id #Here is where we test that an ID is present.
      self.from_place_id = from_place_id
    else
      from_place = Place.new('nongeocoded_address'=>nongeocoded_address)
      from_place.name = nongeocoded_address
      from_place.owner = self.owner
      from_place.save()
      self.from_place_id = from_place.id
    end
  end

  def from_place= place
    @from_place = initialize_place place
    # TODO Not sure about the reliability of this. Ditto below.
    places << @from_place
  end

  def from_place
    @from_place ||= places[0]
  end

  def to_place= place
    @to_place = initialize_place place
    places << @to_place
  end

  def to_place
    @to_place ||= places[1]
  end

  private

  def initialize_place place
    Rails.logger.info "initialize_place"
    if owner.nil?
      Rails.logger.info "No owner, just using place as is: #{place.inspect}"
      user_place = place
    else
      Rails.logger.info "Have owner, looking up #{place.inspect}"
      user_place = UserPlace.find_by_name_and_user_id(place[:nongeocoded_address], owner.id) || place
      Rails.logger.info "After lookup, user_place is #{user_place}"
    end
    TripPlace.new(user_place.respond_to?(:attributes) ?
      user_place.attributes.except('id', 'user_id', 'created_at', 'updated_at') :
      user_place)
  end

end
