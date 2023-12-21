# frozen_string_literal: true

# Query class - see config/reports.yml for description
ArklistQuery < IdlistQuery
  def get_title
    "Arklist Query for #{get_params.length} arks"
  end

  def get_params
    @myparams['arklist'].split(',')
  end

  def get_where
    %{
      where
      o.ark in (
      } + get_placeholders +
      %{
      )
    }
  end
end
