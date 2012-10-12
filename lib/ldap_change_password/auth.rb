module LdapChangePassword
  class Auth < Warden::Strategies::Base
    def valid?
      params['login'] || params['password']
    end

    def authenticate!
      if LdapChangePassword::User.authenticate?(params['login'], params['password'])
        @user = LdapChangePassword::User.find_by_login(params['login'])
        success! @user, "Welcome #{@user.login}"
      else
        fail!
      end
    end

    def authorize!
      true
    end
  end
end
Warden::Strategies.add :auth_ldap, LdapChangePassword::Auth
