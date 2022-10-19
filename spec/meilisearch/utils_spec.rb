# frozen_string_literal: true

module MeiliSearch
  RSpec.describe Utils do
    describe '.warn_on_non_conforming_attribute_names' do
      it 'warns when using camelCase attributes' do
        attrs = { attributesToHighlight: ['field'] }

        expect do
          Utils.warn_on_non_conforming_attribute_names(attrs)
        end.to output(include('Attributes will be expected to be snake_case', 'attributesToHighlight')).to_stderr
      end

      it 'warns when using a mixed case' do
        attrs = { distinct_ATTribute: 'title' }

        expect do
          Utils.warn_on_non_conforming_attribute_names(attrs)
        end.to output(include('Attributes will be expected to be snake_case', 'distinct_ATTribute')).to_stderr
      end

      it 'does not warn when using snake_case' do
        attrs = { q: 'query', attributes_to_highlight: ['field'] }

        expect do
          Utils.warn_on_non_conforming_attribute_names(attrs)
        end.not_to output.to_stderr
      end
    end
  end
end
