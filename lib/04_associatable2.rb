require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    # ...
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      source_class = source_options.class_name.constantize
      through_class = through_options.class_name.constantize

      join_line = "#{source_class.table_name} ON
      #{through_class.table_name}.#{source_options.foreign_key} =
      #{source_class.table_name}.#{through_options.primary_key}"

      where_line = "#{through_class.table_name}.id = ?"

      arr = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key))
        SELECT
          #{source_class.table_name}.*
        FROM
          #{through_class.table_name}
        JOIN
          #{join_line}
        WHERE
          #{where_line}
      SQL

      source_class.parse_all(arr).first
    end
  end
end
