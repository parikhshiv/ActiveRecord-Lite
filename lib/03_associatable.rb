require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    basic = name.to_s.capitalize
    @foreign_key = options[:foreign_key] || (basic + "Id").underscore.to_sym
    @class_name = options[:class_name] || basic
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    basic = self_class_name.to_s.capitalize + "ID"
    @foreign_key = options[:foreign_key] || basic.underscore.to_sym
    @class_name = options[:class_name] || name.to_s.capitalize.singularize
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      match = self.send(options.foreign_key)
      options.model_class.where({options.primary_key => match}).first
    end
  end

  def has_many(name, options = {})
    name = options[:class] || name.to_s
    option = HasManyOptions.new(name, self, options)
    define_method(name) do
      match = self.send(option.primary_key)
      option.model_class.where({option.foreign_key => match})
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
