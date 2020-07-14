class OwnerQuery < AdminQuery
  def get_sql
    "SELECT id, name FROM inv.inv_owners;"
  end
end
