module Hubspot
  
  # Finds blogs
  #
  # Finds:
  # Hubspot::Blog.find :all, :params => { :max => 10 }
  # Hubspot::Blog.find <GUID>  
  class Contact < Hubspot::Base
    self.site = 'https://api.hubapi.com/contacts/v1'
    
    schema do
      string 'vid'
    end
    
    alias_attribute :id, :vid
    
    # ==== ActiveResource Overrides ====
    
    def self.element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name.singularize}/vid/#{URI.escape id.to_s}/profile.#{format.extension}#{query_string(query_options)}"
    end      

    
    def self.collection_path(prefix_options = {}, query_options = nil)
      puts "#### self.collection_path"
      puts "prefix_options: #{prefix_options}"
      puts "query_options: #{query_options}"
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}lists/all/contacts/all.#{format.extension}#{query_string(query_options)}"
    end      

    class << self
      def instantiate_collection(collection, prefix_options = {})
        collection = collection['contacts'] if collection.is_a?(Hash)
        # collection.collect! { |record| record }
        collection.collect! { |record| instantiate_record(record, prefix_options) }
      end
      
      def instantiate_record(record, prefix_options = {})
        puts "#### self.collection_path"
        puts "record: #{record}"
        new(record, true).tap do |resource|
          puts "resource: #{resource}"
          puts "resource.prefix_options: #{resource.prefix_options}"
          resource.prefix_options = prefix_options
        end
      end
    end

    def find_or_create_resource_for(name)
      puts "#### find_or_create_resource_for(name)"
      puts "name: #{name}"

      resource_name = name.to_s.gsub('-','_').camelize
      puts "resource_name #{resource_name}"
      
      const_args = RUBY_VERSION < "1.9" ? [resource_name] : [resource_name, false]
      if self.class.const_defined?(*const_args)
        self.class.const_get(*const_args)
      else
        ancestors = self.class.name.split("::")
        if ancestors.size > 1
          asdf = find_or_create_resource_in_modules(resource_name, ancestors)
        else
          if Object.const_defined?(*const_args)
            Object.const_get(*const_args)
          else
            create_resource_for(resource_name)
          end
        end
      end
    end
    
    def update
      connection.post(element_path(prefix_options), encode, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    
    # # TODO Change - to _
    # def method_missing(method_symbol, *arguments) #:nodoc:
    #   puts method_symbol
    #   puts arguments
    #   method_name = method_symbol.to_s
    # 
    #   if method_name =~ /(=|\?)$/
    #     case $1
    #     when "="
    #       attributes[$`] = arguments.first
    #     when "?"
    #       attributes[$`]
    #     end
    #   else
    #     return attributes[method_name] if attributes.include?(method_name)
    #     # not set right now but we know about it
    #     return nil if known_attributes.include?(method_name)
    #     super
    #   end
    # end
  end
end