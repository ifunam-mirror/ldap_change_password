ldap_change_password
====================

Web application to change your ldap password based on the sinatra framework.

## Requeriments

* Ruby 1.9.3-p194
* rvm 1.14.1
* Bundler version 1.1.4
* shotgun version 0.9
* cracklib2

##How to configure this application

Edit the files app.yml and ldap.yml in the config directory

##How to use this application
  
        $ cd ldap_change_password
        $ bundle install
        $ gem install shotgun
        $ shotgun

##Notes

* Mac OS, to avoid problems to install the rubylibcrack gem you should
  export the DYLD_LIBRARY_PATH=/opt/local/lib.
