# Records injury-related information.
# Attaches an Event to this record with the 
# build_injury_event and update_injury_event hooks.
class InjuryRecord < ActiveRecord::Base

  # ----- ATTRIBUTES ACCESSIBLE -----
  attr_accessible :name, :description, :start_date, :end_date, :severity, :ongoing
 
  # ----- ASSOCIATIONS ----- 
  has_one    :event, :as => :schedulable, :dependent => :destroy
  belongs_to :user

  # ----- VALIDATION CALLS ----
  validates_presence_of :name, :message => 'Injury must have a name'
  validates_presence_of :description, :message => 'Injury must have a description'
  validates_presence_of :start_date, :message => 'Injury must have a start date'
  validates_presence_of :severity, :message => 'Injury must have a severity level'
  validate :severity_within_bounds

  # ----- CALLBACKS -----
  after_create  :build_injury_event
  after_update  :update_injury_event

  # ----- CUSTOM VALIDATION METHODS -----
  # Ensures that the provided severity value is between 1 and 10 inclusive.
  def severity_within_bounds
    if not (1..10).include? self[:severity]
      self.errors[:base] << 'Severity must be between 1 and 10 (inclusive)'
    end
  end

  private
  # ----- CUSTOM CALLBACK METHODS -----
  def build_injury_event
    if self.start_date
      self.event = Event.create!( :name => self.name, :start_at => self.start_date,
                                 :end_at => self.end_date,
                                 :user => self.user, :event_color => EventColor.red )
    end
    true
  end

  def update_injury_event
    if self.start_date
      if self.event
        self.event.update_attributes!( :name => self.name, :start_at => self.start_date,
                                       :end_at => self.end_date )
      else
        build_injury_event
      end
    end
  end

end
