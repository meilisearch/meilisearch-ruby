# frozen_string_literal: true

require 'openssl/hmac'

module MeiliSearch
  module TenantToken
    HEADER = {
      typ: 'JWT',
      alg: 'HS256'
    }.freeze

    def generate_tenant_token(search_rules, api_key: nil, expires_at: nil)
      signature = retrieve_valid_key!(api_key, @api_key)
      expiration = validate_expires_at!(expires_at)
      rules = validate_search_rules!(search_rules)
      unsigned_data = build_payload(expiration, rules, signature)

      combine(unsigned_data, to_base64(sign_data(signature, unsigned_data)))
    end

    private

    def build_payload(expiration, rules, signature)
      payload = {
        searchRules: rules,
        apiKeyPrefix: signature[0..7],
        exp: expiration
      }.compact

      combine(encode(HEADER), encode(payload))
    end

    def validate_expires_at!(expires_at)
      return unless expires_at
      return expires_at.to_i if expires_at > Time.now

      raise ExpiredSignature
    rescue StandardError
      raise ExpiredSignature
    end

    def validate_search_rules!(data)
      return data if data

      raise InvalidSearchRules
    end

    def retrieve_valid_key!(*keys)
      key = keys.compact.find { |k| !k.empty? }

      raise InvalidApiKey if key.nil?

      key
    end

    def sign_data(key, msg)
      OpenSSL::HMAC.digest('SHA256', key, msg)
    end

    def to_base64(data)
      Base64.urlsafe_encode64(data, padding: false)
    end

    def encode(data)
      to_base64(JSON.generate(data))
    end

    def combine(*parts)
      parts.join('.')
    end
  end
end
