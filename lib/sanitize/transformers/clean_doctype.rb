# frozen_string_literal: true

class Sanitize; module Transformers

  CleanDoctype = lambda do |env|
    return if env[:is_allowlisted]

    node = env[:node]

    if node.type == Nokogiri::XML::Node::DTD_NODE
      if env[:config][:allow_doctype]
        if node.name != "html"
          document = node.document
          node.unlink
          document.create_internal_subset("html", nil, nil)
        end
      else
        node.unlink
      end
    end
  end

end; end
