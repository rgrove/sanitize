class Sanitize; module Transformers

  CleanCDATA = lambda do |env|
    return if env[:is_whitelisted]

    node = env[:node]

    if node.cdata?
      node.replace(Nokogiri::XML::Text.new(node.text, node.document))
    end
  end

end; end
