require_relative "../config/environment.rb"
#require 'active_support/inflector'

class InteractiveRecord
    #ATTRIBUTES = {"id" => "integer",
    #        "name" => "text",
    #        "grade" => "text"}
    PRIMARY_KEY = "id"

    def self.find_by(hash)
        values = []
        search_fields = hash.map do |key, value|
            values << value
            "#{key}=?"
        end.join(" AND ")
        
        sql_statement = <<-SQL
            SELECT #{ATTRIBUTES.keys.join(",")} FROM #{table_name} WHERE #{search_fields}
        SQL
        rows = DB[:conn].execute(sql_statement, values)
        hash_from_db(rows)
    end

    def self.column_names
        ATTRIBUTES.keys.to_a
    end

    def self.table_name
        "#{self.to_s.downcase}s"
    end

    def table_name_for_insert
        self.class.table_name
    end

    def self.fields
        ATTRIBUTES.select {|attribute| attribute != PRIMARY_KEY}.map do |attribute, datatype|
            "#{attribute}" 
        end
    end

    def values
        self.class.fields.collect do |field|
            self.send(field)
        end
    end

    def initialize(attributes = {})
        create_attr_accessors(*self.class.column_names)
        attributes.each do |attribute, value|
            self.send("#{attribute}=", value)
        end
    end

    def create_attr_accessors(*args)
        args.each do |arg|
            #self.class_eval("def #{arg};@#{arg};end")
            #self.class_eval("def #{arg}=(val);@#{arg}=val;end")                      
        end
    end

    def persisted?
        !!@id
    end
    def save
        if persisted?
            update
        else
            insert
        end
        self
    end
    
    def insert
        question_marks = (fields.length.times).map {"?"}.join(",")
        sql_statement = <<-SQL
            INSERT INTO #{table_name} (#{self.class.fields.join(", ")}) VALUES (#{question_marks});
        SQL
        DB[:conn].execute(sql_statement, *values)
        sql_statement = "SELECT last_insert_rowid()"
        @id = DB[:conn].execute(sql_statement)[0][0]
    end

    def update
        fields_with_question_marks = fields.map {|field| "#{field}=?" }.join(",")
        sql_statement = <<-SQL
            UPDATE #{table_name} SET #{fields_with_question_marks} WHERE #{PRIMARY_KEY}=?
        SQL
        DB[:conn].execute(sql_statement, *values, id)
    end

    def self.new_from_db(row)
        return nil if row.nil?
        hash = {}
        ATTRIBUTES.keys.each_with_index do |attribute, index|
            hash[attribute] = row[index]
        end
        self.new(hash)
    end

    def self.hash_from_db(rows)
        return nil if rows.nil?

        rows.map do |row|
            hash = {}
            ATTRIBUTES.keys.each_with_index do |attribute, index|
                hash[attribute] = row[index]
                hash[index] = row[index] #Don't understand why the test would want the data indexed and associated
            end
            hash
        end
    end

    #helper functions
    def table_name
        self.class.table_name
    end

    def primary_key_type
        self.class.primary_key_type
    end

    def fields
        self.class.fields
    end

    # Methos to pass tests
    def col_names_for_insert
        self.class.fields.join(", ")
    end
    def values_for_insert
        values.map {|value| "'#{value}'" }.join(", ")
    end

end