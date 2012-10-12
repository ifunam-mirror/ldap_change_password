# Add our lib dir to the load path
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ldap_change_password'

# If we're in development, Sinatra already outputs Rack::CommonLogger
# to STDOUT. We want to add the CommonLogger, only in non-development
# environments.
run LdapChangePassword::App
