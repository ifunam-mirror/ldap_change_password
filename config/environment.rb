require 'rubygems'
require 'bundler'
require 'configatron'
Bundler.setup
Bundler.require(:default)

# Set up default environment
env = ((defined?RACK_ENV) ? RACK_ENV : ENV['RACK_ENV']) || 'development'

require 'pry' if env == 'development'

configatron.env = env

app_conf = File.expand_path '../app.yml', __FILE__
if File.exist? app_conf
  configatron.app = YAML::load_file(app_conf)
else
  abort "The #{app_conf} file does not exist!"
end

ldap_conf = File.expand_path '../ldap.yml', __FILE__
if File.exist? ldap_conf
  configatron.configure_from_hash({:ldap => YAML::load_file(ldap_conf)[env]})
else
  abort "The #{ldap_conf} file does not exist!"
end
