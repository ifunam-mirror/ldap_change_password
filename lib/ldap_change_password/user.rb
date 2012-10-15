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
require 'rubylibcrack'
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
        new(@ldap_user) unless @ldap_user.nil?
      end

      def authenticate?(login, password)
        @ldap_user = LdapChangePassword::LDAP::User.find_by_login(login)
        @ldap_user.authenticate?(password) unless @ldap_user.nil?
      end
    end

    attr_reader   :login, :fullname, :email, :group, :expiration_date
    attr_accessor :password, :current_password
    define_attribute_methods  [:password, :current_password]
    validates :password, :presence => true, :confirmation => true, :length => {:within => 6..40}
    validates_presence_of :current_password, :on => :update
    class_attribute :_attributes
    self._attributes = []

    def initialize(entry)
      @ldap_entry = entry
      set_attr_readers!
    end

    def attributes
      self._attributes.inject({}) do |hash, attr|
        hash[attr.to_s] = send(attr)
        hash
      end
    end

    def valid?
      super and current_password_valid? and new_password_strong?
    end

    def save
      valid? ? update : false
    end

    def update
      if valid?
        update_ldap_password!
        true
      else
        false
      end
    end

    def update_attributes(hash)
      sanitize_for_mass_assignment(hash).each do |attribute, value|
        instance_variable_set("@#{attribute}", value)
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

    def current_password_valid?
      unless @ldap_entry.authenticate?(current_password)
        errors.add :current_password, "doesn't match"
        false
      else
        true
      end
    end

    def update_ldap_password!
      if password_was != password
        @ldap_entry.update_password(password)
      end
    end

    def new_password_strong?
       pw = Cracklib::Password.new(password)
       if pw.strong?
          true
       else
          errors.add pw.message
          false
       end
    end

    def set_attr_readers!
      [:login, :fullname, :email, :group, :expiration_date, :password].each do |attr_name|
        if @ldap_entry.respond_to? attr_name
          self.instance_variable_set("@#{attr_name}", @ldap_entry.send(attr_name))
          self._attributes << attr_name
        end
        self.password_will_change!
      end
    end
  end
end
