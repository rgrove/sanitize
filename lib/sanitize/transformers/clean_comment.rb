# frozen_string_literal: true

class Sanitize; module Transformers

  CleanComment = lambda do |env|
    node = env[:node]

    if node.type == Nokogiri::XML::Node::COMMENT_NODE
      node.unlink unless env[:is_allowlisted]
    end
  end

end; end
