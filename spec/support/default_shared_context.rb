# frozen_string_literal: true

RSpec.shared_context 'test defaults' do
  let(:client) { Meilisearch::Client.new(URL, MASTER_KEY, { timeout: 2, max_retries: 1 }) }

  before do
    clear_all_indexes(client)
    clear_all_keys(client)
  end

  def random_uid
    SecureRandom.hex(4)
  end

  def snake_case_word(camel_cased_word)
    return camel_cased_word unless /[A-Z]/.match?(camel_cased_word)

    camel_cased_word.gsub(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, '_')
                    .tr('-', '_')
                    .downcase
  end
end
