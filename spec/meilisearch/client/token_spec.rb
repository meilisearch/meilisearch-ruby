# frozen_string_literal: true

require 'jwt'

VERIFY_OPTIONS = {
  required_claims: ['exp', 'apiKeyUid', 'searchRules'],
  algorithm: 'HS256'
}.freeze

RSpec.describe MeiliSearch::TenantToken do
  let(:instance) { dummy_class.new(client_key) }
  let(:dummy_class) do
    Class.new do
      include MeiliSearch::TenantToken

      def initialize(api_key)
        @api_key = api_key
      end
    end
  end

  let(:search_rules) { {} }
  let(:api_key) { SecureRandom.hex(24) }
  let(:client_key) { SecureRandom.hex(24) }
  let(:expires_at) { Time.now.utc + 10_000 }

  it 'responds to #generate_tenant_token' do
    expect(instance).to respond_to(:generate_tenant_token)
  end

  describe '#generate_tenant_token' do
    subject(:token) do
      instance.generate_tenant_token('uid', search_rules, api_key: api_key, expires_at: expires_at)
    end

    context 'with api_key param' do
      it 'decodes successfully using api_key from param' do
        expect do
          JWT.decode token, api_key, true, VERIFY_OPTIONS
        end.to_not raise_error
      end

      it 'tries to decode without the right signature raises a error' do
        expect do
          JWT.decode token, client_key, true, VERIFY_OPTIONS
        end.to raise_error(JWT::DecodeError)
      end
    end

    context 'without api_key param' do
      let(:api_key) { nil }

      it 'decodes successfully using @api_key from instance' do
        expect do
          JWT.decode token, client_key, true, VERIFY_OPTIONS
        end.to_not raise_error
      end

      it 'tries to decode without the right signature raises a error' do
        expect do
          JWT.decode token, api_key, true, VERIFY_OPTIONS
        end.to raise_error(JWT::DecodeError)
      end

      it 'raises error when both api_key are nil' do
        client = dummy_class.new(nil)

        expect do
          client.generate_tenant_token('uid', search_rules)
        end.to raise_error(described_class::InvalidApiKey)
      end

      it 'raises error when both api_key are empty' do
        client = dummy_class.new('')

        expect do
          client.generate_tenant_token('uid', search_rules, api_key: '')
        end.to raise_error(described_class::InvalidApiKey)
      end
    end

    context 'with expires_at' do
      it 'raises error when expires_at is in the past' do
        expect do
          instance.generate_tenant_token('uid', search_rules, expires_at: Time.now.utc - 10)
        end.to raise_error(described_class::ExpireOrInvalidSignature)
      end

      it 'allows generate token with a nil expires_at' do
        expect do
          instance.generate_tenant_token('uid', search_rules, expires_at: nil)
        end.to_not raise_error
      end

      it 'decodes successfully the expires_at param' do
        decoded = JWT.decode token, api_key, false

        expect(decoded.dig(0, 'exp')).to eq(expires_at.to_i)
      end

      it 'raises error when expires_at has a invalid type' do
        ['2042-01-01', 78_126_717_684, []].each do |exp|
          expect do
            instance.generate_tenant_token('uid', search_rules, expires_at: exp)
          end.to raise_error(described_class::ExpireOrInvalidSignature)
        end
      end

      it 'raises error when expires_at is not a UTC' do
        expect do
          instance.generate_tenant_token('uid', search_rules, expires_at: Time.now + 10)
        end.to raise_error(described_class::ExpireOrInvalidSignature)
      end
    end

    context 'without expires_at param' do
      it 'allows generate token without expires_at' do
        expect do
          instance.generate_tenant_token('uid', search_rules)
        end.to_not raise_error
      end
    end

    context 'with search_rules definitions' do
      include_context 'search books with genre'

      before { index.update_filterable_attributes(['genre', 'objectId']).await }

      let(:adm_client) { MeiliSearch::Client.new(URL, adm_key['key']) }
      let(:adm_key) do
        client.create_key(
          description: 'tenants test',
          actions: ['*'],
          indexes: ['*'],
          expires_at: '2042-04-02T00:42:42Z'
        )
      end
      let(:rules) do
        [
          { '*': {} },
          { '*': nil },
          ['*'],
          { '*': { filter: 'genre = comedy' } },
          { books: {} },
          { books: nil },
          ['books'],
          { books: { filter: 'genre = comedy AND objectId = 1' } }
        ]
      end

      it 'accepts the token in the search request' do
        rules.each do |data|
          token = adm_client.generate_tenant_token(adm_key['uid'], data)
          custom = MeiliSearch::Client.new(URL, token)

          expect(custom.index('books').search('')).to have_key('hits')
        end
      end

      it 'requires a non-nil payload in the search_rules' do
        expect do
          client.generate_tenant_token('uid', nil)
        end.to raise_error(described_class::InvalidSearchRules)
      end
    end

    it 'has apiKeyUid with the uid of the key' do
      decoded = JWT.decode(token, api_key, true, VERIFY_OPTIONS).dig(0, 'apiKeyUid')

      expect(decoded).to eq('uid')
    end
  end
end
