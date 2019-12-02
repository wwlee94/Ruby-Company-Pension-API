module Exceptions
    class Base < StandardError
    end

    class NotFoundError < Base
    end

    class PensionApiError < Base
    end

    class VariousCompanyNameError < PensionApiError
    end

    class InvalidRegistrationNameError < PensionApiError
    end

    class InvalidRegistrationNumberError < PensionApiError
    end
end