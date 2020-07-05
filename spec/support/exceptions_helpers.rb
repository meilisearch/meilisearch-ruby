# frozen_string_literal: true

module ExceptionsHelpers
  def raise_meilisearch_api_error_with(http_code)
    raise_exception(an_instance_of(MeiliSearch::ApiError).and(having_attributes(http_code: http_code)))
  end
end
