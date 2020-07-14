class CollectionQuery < AdminQuery
  def get_sql
    "SELECT id, name FROM inv.inv_collections;"
  end
end
