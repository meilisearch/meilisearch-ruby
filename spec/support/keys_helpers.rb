# frozen_string_literal: true

module KeysHelpers
  def clear_all_keys(client)
    keys_array = client.keys
    keys = keys_array.map { |key_object| key_object['key'] }
    keys.each do |key|
      client.delete_key(key)
    end
  end
end
