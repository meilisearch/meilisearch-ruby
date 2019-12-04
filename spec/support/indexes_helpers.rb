module IndexesHelpers
  def clear_all_indexes(client)
    indexes = client.indexes
    uids = indexes.map { |index| index['uid'] }
    uids.each do |uid|
      client.delete_index(uid)
    end
  end
end
