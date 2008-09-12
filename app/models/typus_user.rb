class TypusUser < ActiveRecord::Base

  attr_accessor :password

  validates_presence_of :email, :first_name, :last_name
  validates_presence_of :password, :password_confirmation, :if => :new_record?
  validates_uniqueness_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_confirmation_of :password, :if => lambda { |person| person.new_record? or not person.password.blank? }
  validates_length_of :password, :within => 6..40, :if => lambda { |person| person.new_record? or not person.password.blank? }

  validates_inclusion_of :roles, 
                         :in => Typus::Configuration.roles.keys, 
                         :message => "has to be in #{Typus::Configuration.roles.keys.reverse.join(", ")}."

  before_create :generate_token
  before_save :encrypt_password

  def full_name_with_role
    "#{first_name} #{last_name} (#{roles})"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def reset_password(password, host)
    TypusMailer.deliver_password(self, password, host)
    self.update_attributes(:password => password, :password_confirmation => password)
  end

  def self.authenticate(email, password)
    user = find_by_email_and_status(email, true)
    user && user.authenticated?(password) ? user : nil
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  ##
  # Models the user has access to ...
  #
  def models
    calculate = {}
    self.roles.split(', ').each do |role|
      calculate = Typus::Configuration.roles[role]
    end
    return calculate
  rescue
    "All"
  end

  def can_create?(model)
    self.models[model.to_s].include? "c"
  end

  def can_read?(model)
    self.models[model.to_s].include? "r"
  end

  def can_update?(model)
    self.models[model.to_s].include? "u"
  end

  def can_destroy?(model)
    self.models[model.to_s].include? "d"
  end

protected

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def encrypt(password)
    Digest::SHA1.hexdigest("--#{salt}--#{password}")
  end

  def generate_token
    @attributes['token'] = Digest::SHA1.hexdigest((object_id + rand(255)).to_s).slice(0..15)
  end

end