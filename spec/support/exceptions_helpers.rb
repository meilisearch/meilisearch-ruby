# frozen_string_literal: true

module ExceptionsHelpers
  def raise_meilisearch_api_error_with(http_code, ms_code, ms_type)
    raise_exception(an_instance_of(MeiliSearch::ApiError)
      .and(having_attributes(
        http_code: http_code,
        ms_code: ms_code,
        ms_type: ms_type
      ))
    )
  end

  def raise_bad_request_meilisearch_api_error
    raise_meilisearch_api_error_with(
      400,
      'bad_request',
      'invalid_request_error'
    )
  end

  def raise_index_not_found_meilisearch_api_error
    raise_meilisearch_api_error_with(
      404,
      'index_not_found',
      'invalid_request_error'
    )
  end

  def raise_document_not_found_meilisearch_api_error
    raise_meilisearch_api_error_with(
      404,
      'document_not_found',
      'internal_error' # temporary, should be changed as invalid_request_error in MS API soon
    )
  end
end
