module Mastico
  class Query
    DEFAULT_OPTIONS = {
      term_boost: 1.0,
      prefix_boost: 0.7,
      infix_boost: 0.4,
      fuzzy_boost: 0.2,
      minimum_term_length: 2,
      minimum_prefix_length: 3,
      minimum_infix_length: 3,
      minimum_fuzzy_length: 5,
      fuzziness: 4
    }.freeze

    QUERY_TYPES = [:term, :prefix, :infix, :fuzzy].freeze

    attr_reader :query
    attr_reader :fields
    attr_reader :word_weight
    attr_reader :options

    def initialize(query:, fields:, word_weight: ->(_w) { 1.0 }, options: DEFAULT_OPTIONS)
      @query = query
      @fields = fields
      @word_weight = word_weight
      @options = options
    end

    def perform(scope)
      parts ? scope.query(parts) : scope
    end

    private

    def parts
      clean = query.strip.gsub(/\s+/, ' ').downcase
      terms = clean.split(" ")
      term_parts = terms.map do |term|
        weight = word_weight.call(term)
        next nil if weight == 0.0
        chewy_term_query(term: term, weight: weight)
      end
      term_parts = term_parts.compact
      case term_parts.size
      when 0
        nil
      when 1
        term_parts[0]
      else
        # We have multiple words in the query -
        # all of them **must** match
        {bool: {must: term_parts}} # AND query
      end
    end

    def chewy_term_query(term:, weight:)
      parts = []
      if term.length >= options[:minimum_term_length]
        relevant_fields(:term).each do |field, field_boost|
          parts << chewy_multi_match_term_query(
            query: term,
            fields: [field],
            boost: options[:term_boost] * weight * field_boost
          )
        end
      end
      if term.length >= options[:minimum_prefix_length]
        relevant_fields(:term).each do |field, field_boost|
          parts << chewy_multi_match_prefix_query(
            query: term,
            fields: [field],
            boost: options[:prefix_boost] * weight * field_boost
          )
        end
      end
      if term.length >= options[:minimum_infix_length]
        relevant_fields(:term).each do |field, field_boost|
          parts << chewy_multi_match_infix_query(
            query: term,
            fields: [field],
            boost: options[:infix_boost] * weight * field_boost
          )
        end
      end
      if term.length >= options[:minimum_fuzzy_length]
        relevant_fields(:term).each do |field, field_boost|
          parts << chewy_multi_match_fuzzy_query(
            query: term,
            fields: [field],
            boost: options[:fuzzy_boost] * weight * field_boost
          )
        end
      end
      parts.compact!

      if parts.size > 0
        {bool: {should: parts}} # OR
      end
    end

    def relevant_fields(search_type)
      if fields.is_a? Array
        fields.map {|field| [field, 1]}.to_h
      else
        fields.select do |field, options|
          if options[:types]
            options[:types].include?(search_type)
          else
            true
          end
        end.map do |field, options|
          [field, options.fetch(:boost, 1)]
        end.to_h
      end
    end

    def chewy_multi_match_term_query(query:, fields:, boost: nil)
      return nil if fields.empty?

      lower = query.downcase
      chewy_multi_match_query(
        type: :term, query: lower, fields: fields, options: {boost: boost}
      )
    end

    def chewy_multi_match_prefix_query(query:, fields:, boost: nil)
      return nil if fields.empty?

      lower = query.downcase
      chewy_multi_match_query(
        type: :prefix, query: lower, fields: fields, options: {boost: boost}
      )
    end

    def chewy_multi_match_infix_query(query:, fields:, boost: nil)
      return nil if fields.empty?

      lower = query.downcase
      wildcard = "*#{lower}*"
      chewy_multi_match_query(
        type: :wildcard, query: wildcard, fields: fields, options: {boost: boost}
      )
    end

    def chewy_multi_match_fuzzy_query(query:, fields:, boost: nil)
      return nil if fields.empty?

      lower = query.downcase
      chewy_multi_match_query(
        type: :fuzzy, query: lower, fields: fields,
        options: {boost: boost, fuzziness: options[:fuzziness]}
      )
    end

    def chewy_multi_match_query(type:, query:, fields:, options: {})
      opts = options.dup
      boost = opts.delete(:boost)
      should = fields.map do |f|
        match = {value: query}.merge(opts)
        match[:boost] = boost if boost
        field = {type => {f => match}}
        field
      end
      {bool: {should: should, minimum_should_match: 0}} # OR over fields
    end
  end
end
