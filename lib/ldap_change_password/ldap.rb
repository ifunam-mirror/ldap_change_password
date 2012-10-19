module LdapChangePassword
  module LDAP
    class Adapter
      def initialize(config)
        h = { :host => config.host, :port => config.port, :base => config.base }
        h[:encryption] = { :method => :simple_tls } if config.ssl == true
        @connection = Net::LDAP.new(h)
        @attribute = config.attribute || "uid"
        @config = config
        auth_as_admin!
        @status = @connection.bind
      end

      def successful?
        @status
      end

      def config_hash
        @config.to_hash
      end

      def config_base
        config_hash[:base]
      end

      def dn(login)
        "#{@attribute}=#{login},#{config_base}"
      end

      def authenticate?(login, password)
        @connection.auth dn(login), password
        @connection.bind
      end

      def find_by_login(login)
        auth_as_admin!
        @connection.search(:base => config_base,
                           :filter => Net::LDAP::Filter.eq(@attribute, login),
                           :return_result => true).first
      end

      def update_password(login, password)
        ldap_update(login, [[:replace, :userPassword, Net::LDAP::Password.generate(:sha, password)]])
      end

      private
      def ldap_update(login, operations)
        auth_as_admin!
        @connection.modify(:dn => dn(login), :operations => operations)
      end

      def auth_as_admin!
        @connection.auth @config.admin_user, @config.admin_password
      end
    end

    class User
      class << self
        def find_by_login(login)
          entry = LdapChangePassword.ldap.find_by_login(login)
          new(entry) unless entry.nil?
        end
      end

      def initialize(entry)
        @entry = entry
        @ldap = LdapChangePassword.ldap
      end

      def login
        @entry.uid.first
      end

      def fullname
        @entry.cn.first
      end

      def email
        @entry.mail.first
      end

      def password
        @entry.userpassword.first
      end

      def group
        @entry.ou.first
      end

      def authenticate?(password)
        @ldap.authenticate?(login, password)
      end

      def update_password(password)
        @ldap.update_password(login, password)
      end
    end
  end
end
