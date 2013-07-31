module SSO
  class Basic < Base
    def available?
      controller.api_request? && http_auth_set?
    end

    def authenticate!
      self.user = controller.authenticate_with_http_basic do |u, p|
        User.try_to_login(u, p)
      end.login
    end

    def authenticated?
      User.current.present? ? User.current : authenticate!
    end

    def http_auth_set?
      request.env['HTTP_AUTHORIZATION']   ||
      request.env['X-HTTP_AUTHORIZATION'] ||
      request.env['X_HTTP_AUTHORIZATION'] ||
      request.env['REDIRECT_X_HTTP_AUTHORIZATION']
    end

  end
end
