# frozen_string_literal: true

module ExceptionsHelpers
  def raise_meilisearch_http_error_with(http_code)
    raise_exception(an_instance_of(MeiliSearch::HTTPError).and(having_attributes(code: http_code)))
  end
end
