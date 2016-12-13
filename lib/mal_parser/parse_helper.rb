module MalParser
  module ParseHelper
    NOKOGIRI_SAVE_OPTIONS = Nokogiri::XML::Node::SaveOptions::AS_HTML |
      Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

    NO_SYNOPSIS_TEXT = [
      'No synopsis has been added for this',
      'No biography written.',
      'No summary yet.'
    ]

    def doc
      @doc ||= Nokogiri::HTML html
    end

    def html
      @html ||= MalParser.configuration.http_get.call url
    end

    def parse_line text
      node = dark_texts.find { |v| v.text.start_with? "#{text}:" }&.next
      return unless node

      text = node.text.strip
      text.empty? ? node.next&.text&.strip : text
    end

    def parse_links text
      dark_texts
        .find { |v| v.text.start_with? "#{text}:" }
        &.parent
        &.css('a')
        &.map { |node| parse_link node }
    end

    def parse_link node
      url = node.attr 'href'

      {
        id: extract_id(url),
        name: node.text
      }
    end

    def dark_texts
      @dark_texts ||= doc.css('span.dark_text')
    end

    def parse_date date
      # if date.match /^\w+\s+\d+,$/
        # nil
      # elsif date.match(/^\d+$/)
      if date =~ /^\d+$/
        Date.new date.to_i
      else
        Date.parse(date)
      end

    rescue StandardError
      nil
    end

    def extract_id url
      url.match(%r{/(?<id>\d+)(/|$)})[:id].to_i
    end

    def no_synopsis?
      NO_SYNOPSIS_TEXT.any? { |phrase| html.include? phrase }
    end
  end
end