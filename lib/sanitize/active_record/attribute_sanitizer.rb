class Sanitize
  module AttributeSanitizer
    extend ActiveSupport::Concern
  
      module ClassMethods
        attr_reader :attributes_requiring_sanitization
        attr_reader :santize_options
        def sanitize_attributes(*attrs)
          @santize_options = {
            :sanitation_level => Sanitize::Config::BASIC
          }.merge(attrs.extract_options!)
              
          @attributes_requiring_sanitization = attrs
          self.send(:before_validation, :sanitize_attribute_before_validation)
        end
      end
    
      module InstanceMethods
        def sanitize_attribute_before_validation
          self.class.attributes_requiring_sanitization.each do |dirty_attr|
            self[dirty_attr] = Sanitize.clean(self[dirty_attr], self.class.santize_options[:sanitation_level]) unless self[dirty_attr].nil?
          end
        end
      
      end
    
  end
end