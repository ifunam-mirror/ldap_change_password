module LdapChangePassword
  class << self
    attr_accessor :env, :app, :ldap
  end
end

require_relative '../config/environment.rb'
require_relative 'ldap_change_password/ldap'

@ldap = LdapChangePassword::LDAP::Adapter.new(configatron.ldap)

if @ldap.successful?
  LdapChangePassword.env = configatron.env
  LdapChangePassword.app = configatron.app
  LdapChangePassword.ldap = @ldap

  %w(user auth app).each do |file_name|
    require_relative "ldap_change_password/#{file_name}"
  end
else
  abort "Ldap connection can not be established" 
end
