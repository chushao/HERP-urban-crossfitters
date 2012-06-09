# Stores information for a particular workout session.
# Automatically creates a corresponding Event with the
# build_workout_event and update_workout_event hooks.
class WorkoutRecord < ActiveRecord::Base

  # ----- ATTRIBUTES ACCESSIBLE -----
  attr_accessible :date_performed, :note, :points, :time, :rounds, :workout_id 

  # ----- NAMED SCOPES -----
  scope :ordered, :order => 'date_performed DESC'

  # ----- ASSOCIATIONS -----
  belongs_to  :user
  belongs_to  :workout
  has_one     :trainer
  has_one     :event, :as => :schedulable, :dependent => :destroy

  accepts_nested_attributes_for :workout

  # ----- VALIDATION CALLS -----
  validate :at_least_one_metric
  validates_presence_of :workout_id,
                        :message => 'A workout record must be associated with a workout'
  validates_presence_of :date_performed,
                        :message => 'A workout record must have a date for when it was entered'

  # ----- CALLBACKS -----
  after_create  :build_workout_event
  after_update  :update_workout_event
  
  after_create  :check_personal_record
  after_update  :check_personal_record

  # ----- CLASS METHODS -----
  def self.latest(user_id)
    WorkoutRecord.where(:user_id => user_id).ordered.first
  end

  # ----- INSTANCE METHODS -----
  # Takes a hash of hours, minutes, and seconds and converts to seconds.
  def time=(val)
    self[:time] = (val[:hours].to_i * 3600) + (val[:minutes].to_i * 60) + (val[:seconds].to_i)
  end

  # Returns a hash containing :hours, :minutes, and :seconds representing the time,
  # and also :string, which contains a string representation of the time, and :insecs,
  # which contains the time in seconds.
  def time
    h = self[:time] / 3600
    m = (self[:time] / 60) % 60
    s = (self[:time] % 60)
    str = "#{h}h:#{m}m:#{s}s"
    if self[:time] != 0
      {:insecs => self[:time], :hours => h.to_i, :minutes => m, :seconds => s, :string => str}
    else
      nil
    end
  end

  # ----- CUSTOM VALIDATION METHODS -----
  # Ensures that at least one workout metrics was provided.
  def at_least_one_metric
    unless(self.points || self.time || self.rounds)
      self.errors[:base] << 'At least one metric must be entered'
    end
  end


  private
  # ----- CUSTOM CALLBACK METHODS -----
  def build_workout_event
    if self.date_performed
      self.event = Event.create( :name => self.workout.name, :start_at => self.date_performed,
                                 :end_at => self.date_performed,
                                 :user => self.user, :event_color => EventColor.blue )
    end
    true
  end

  def update_workout_event
    if self.date_performed
      if self.event
        self.event.update_attributes( :name => self.workout.name,
                                      :start_at => self.date_performed,
                                      :end_at => self.date_performed,
                                      :event_color => EventColor.blue )
      else
        build_workout_event
      end
    end
  end

  def check_personal_record
    pr = PersonalRecord.get_record_for(self.user_id, self.workout_id)
    if pr
      pr.save
    else
      pr = PersonalRecord.new
      pr.workout_record = self
      pr.save
    end
  end
end
