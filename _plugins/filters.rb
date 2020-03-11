module Jekyll
  module HelpfulFilters
    def basename(input)
      File.basename(input, '.adoc')
    end

    def series_index(input, series_name)
      post_series = @context.registers[:site].data['post_series']
      entries = post_series.dig(series_name, 'entries')
      return nil unless entries

      idx = entries.bsearch_index { |e| e >= input }
      prev = idx.zero? ? nil : entries[idx - 1]
      { 'prev' => prev, 'next' => entries[idx + 1] }
    end
  end
end

Liquid::Template.register_filter(Jekyll::HelpfulFilters)
