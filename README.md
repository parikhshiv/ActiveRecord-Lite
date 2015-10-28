# Active Record Lite

### Active Record built from scratch...cool!

'Has many' association built from HasManyOptions class:

```
def has_many(name, options = {})
  name = options[:class] || name.to_s
  option = HasManyOptions.new(name, self, options)
  define_method(name) do
    match = self.send(option.primary_key)
    option.model_class.where({option.foreign_key => match})
  end
end
```
