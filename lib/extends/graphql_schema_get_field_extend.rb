# frozen_string_literal: true

if GraphQL::Schema.instance_method(:get_field).arity == 2
  module GraphqlSchemaGetFieldExtend
    def get_field(parent_type, field_name, _context = GraphQL::Query::NullContext)
      super(parent_type, field_name)
    end
  end

  GraphQL::Schema.prepend(GraphqlSchemaGetFieldExtend)
end
