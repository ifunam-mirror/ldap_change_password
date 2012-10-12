# User class Description:
#
# This class is designed to work only to change the password of an ldap user. If you want to save the changes of 
# other ldap attributes you must modify the User class behaviour.
#
# This class does not support the user creation or delete operations for the LDAP service, this was designed to
# do a simple operation.
#
# encoding: utf-8
#
require 'digest/sha1'
require 'active_model'
module LdapChangePassword
  class User

    include ActiveModel::Dirty
    include ActiveModel::AttributeMethods
    include ActiveModel::Validations
    include ActiveModel::Serialization
    include ActiveModel::MassAssignmentSecurity
    extend  ActiveModel::Translation

    class << self
      def find_by_login(login)
        @ldap_user = LdapChangePassword::LDAP::User.find_by_login(login)
        entry_to_record(@ldap_user) unless @ldap_user.nil?
      end

      def authenticate?(login, password)
        @ldap_user = LdapChangePassword::LDAP::User.find_by_login(login)
        @ldap_user.authenticate?(password) unless @ldap_user.nil?
      end

      def attributes(*names)
        attr_accessor *names
        define_attribute_methods names
      end

      private
      def entry_to_record(entry)
        record = new(:login => entry.login, :email => entry.email, :fullname => entry.fullname,
                    :password => entry.password, :group => entry.group)
        record.ldap_entry = entry
        record
      end
    end

    attr_reader :login, :fullname, :email, :group, :expiration_date
    attr_accessor :password, :current_password
    define_attribute_methods  [:password, :current_password]
    validates :password, :presence => true, :confirmation => true, :length => {:within => 6..40}
    validates_presence_of :current_password, :on => :update
    class_attribute :_attributes
    self._attributes = []

    def initialize(attributes={})
      self.attributes=(attributes)
      self
    end

    def ldap_entry=(entry)
      @ldap_entry = entry
    end

    def attributes=(hash)
      sanitize_for_mass_assignment(hash).each do |attribute, value|
        self.instance_variable_set("@#{attribute}", value)
        if [:password, :current_password].include? attribute
          send("#{attribute}_will_change!")
          self._attributes << attribute
        end
      end
    end

    def attributes
      self._attributes.inject({}) do |hash, attr|
        hash[attr.to_s] = send(attr)
        hash
      end
    end

    def valid?
      validates_current_password!
      super
    end

    def save
      valid? ? update : false
    end

    def update
      if valid?
        update_ldap_password!
        return true
      else
        return false
      end
    end

    def update_attributes(hash)
      sanitize_for_mass_assignment(hash).each do |attribute, value|
        send("#{attribute}=", value)
      end
      update
    end

    def fullname
      force_encoding @fullname
    end

    def serializable_hash
      super :only => :login
    end

    private
    def force_encoding(string)
      string.to_s.force_encoding('ascii').to_s
    end

    def validates_current_password!
      unless @ldap_entry.authenticate?(current_password)
        errors.add :current_password, "doesn't match"
      end
    end

    def update_ldap_password!
      if password_was != password
        @ldap_entry.update_password(password)
      end
    end
  end
end
