require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    arr = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    arr.first.map {|el| el.to_sym}
  end

  def self.finalize!
    self.columns.each do |name|
      define_method("#{name}=") do |arg|
        self.attributes[name] = arg
      end

      define_method("#{name}") do
        self.attributes[name]
      end
    end

    define_method(:attributes) do
      @attributes ||= {}
    end
  end

  def self.table_name=(table_name)
    instance_variable_set("@table_name", table_name)
  end

  def self.table_name
    value  = instance_variable_get("@table_name")
    value ||= self.to_s.tableize
  end

  def self.all
    arr = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    self.parse_all(arr)
  end

  def self.parse_all(results)
    cla = self
    results.map do |result|
      cla.new(result)
    end
  end

  def self.find(id)
    arr = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    self.parse_all(arr).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=".to_sym, value)
    end
  end

  def attributes
    # ...
  end

  def attribute_values
    self.class.columns.map {|col| send(col)}
  end

  def insert
    col_names = self.class.columns.join(',')
    question_marks = Array.new(col_names.split(',').length) {'?'}.join(',')
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_obj = self.class.columns.map {|col| "#{col} = ?"}.join(',')
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_obj}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
