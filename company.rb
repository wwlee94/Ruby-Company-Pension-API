#encoding: UTF-8
class Company
    def initialize(name, registration_number, registration_name)
        @name = name
        @registration_number = registration_number
        @registration_name = registration_name
    end

    def name
        @name
    end

    def registration_number
        @registration_number
    end

    def registration_name
        @registration_name
    end
end