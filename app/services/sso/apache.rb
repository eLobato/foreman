module SSO
  class Apache < Base
    delegate :session, :to => :controller

    CAS_USERNAME = 'REMOTE_USER'
    def available?
      return false unless Setting['authorize_login_delegation']
      return false if controller.api_request? and not Setting['authorize_login_delegation_api']
      true
    end

    # If REMOTE_USER is provided by the web server then
    # authenticate the user without using password.
    def authenticated?
      if (self.user = request.env[CAS_USERNAME]).present?
        store
        true
      else
        false
      end
    end

    def logout_url
      "#{Setting['apache_logout_url']}"
    end

    def store
      session[:sso_method] = self.class.to_s
    end

  end
end
