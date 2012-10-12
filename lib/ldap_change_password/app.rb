require 'sinatra'
require 'rack-flash'
require 'rack/protection'
require 'rack/csrf'
require 'logger'
require 'sinatra/i18n'
require 'sinatra_warden'

module LdapChangePassword
  class App < Sinatra::Base

    set :environment, LdapChangePassword.env
    set :root, File.join(File.dirname(__FILE__), '..', '..')

    enable :logging, :dump_errors, :raise_errors
    use Rack::CommonLogger, Logger.new("log/#{LdapChangePassword.env}.log")

    # Settings for session handling and flash messages
    #
    # Note:
    #   Warden does NOT support the expire_date attribute for the cookie of session.
    #   The expiration date functionality is replaced with the code of the method
    #   * method_name* in the User class.
    use Rack::Session::Cookie, LdapChangePassword.app['cookie'].merge('path' => '/')
    use Rack::Flash, :accessorize => [:error, :notice, :success]
    enable :static

    # Protection agaist typical web attacks
    use Rack::Protection
    use Rack::Protection::AuthenticityToken
    use Rack::Protection::RemoteReferrer, :allow_empty_referrer => false
    use Rack::Protection::FormToken
    use Rack::Csrf

    helpers do
      def csrf_token
        Rack::Csrf.csrf_token(env)
      end

      def csrf_tag
        Rack::Csrf.csrf_tag(env)
      end

      def authenticity_token
        %Q{<input type="hidden" name="authenticity_token" value="#{session[:csrf]}"/>}
      end
    end

    # Internationalization
    locale_file = File.join(root, 'config', 'locales', "#{LdapChangePassword.app['locale']}.yml")
    if File.exist? locale_file
      set :locales, locale_file
      register Sinatra::I18n
    end

    # sinatra_warden settings
    set :auth_login_template, '/login'
    set :auth_success_path, '/dashboard'
    set :back, '/'
    use Warden::Manager do |manager|
      manager.failure_app = LdapChangePassword::App
      manager.default_strategies :auth_ldap
      manager.serialize_into_session { |user| user.login }
      manager.serialize_from_session { |login| LdapChangePassword::User.find_by_login(login) }
    end
    register Sinatra::Warden

    get '/' do
      if warden.authenticated?
        redirect '/dashboard'
      else
        redirect '/login'
      end
    end

    get '/dashboard' do
      authorize!
      haml :dashboard
    end

    get '/change_password' do
      authorize!
      haml :change_password
    end

    post '/change_password/?' do
      authorize!
      if current_user.update_attributes(valid_params!)
        flash[:success] = t('change_password.flash.success_msg')
      else
        flash[:error] = t('change_password.flash.error_msg')
      end
      haml :change_password
    end

    private
    def valid_params!
      %w(password password_confirmation current_password).inject({}) do |hash, field_name|
        hash[field_name] = params[field_name] if params.has_key? field_name
        hash
      end
    end
  end
end
