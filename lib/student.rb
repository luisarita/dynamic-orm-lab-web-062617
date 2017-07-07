require_relative "../config/environment.rb"
#require 'active_support/inflector'
require 'interactive_record.rb'

class Student < InteractiveRecord
    attr_accessor :name, :id, :grade

    @ATTRIBUTES = {
        "id" => "integer",
        "name" => "text",
        "grade" => "text"
    }

    def self.find_by_name(argument)
        find_by({:name => argument})
    end
end
