module SSO
  class Basic < Base
    def available?
      controller.api_request? && http_auth_set?
    end

    def authenticate!
      user = controller.authenticate_with_http_basic { |u, p| User.try_to_login(u, p) }
      self.user = user.login if user.present?
    end

    def authenticated?
      User.current.present? ? User.current : authenticate!
    end

    def http_auth_set?
      request.authorization.present? && request.authorization =~ /\ABasic/
    end

  end
end
