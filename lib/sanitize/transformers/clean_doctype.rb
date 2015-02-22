# encoding: utf-8

class Sanitize; module Transformers

  CleanDoctype = lambda do |env|
    node = env[:node]

    if node.type == Nokogiri::XML::Node::DTD_NODE
      node.unlink unless env[:is_whitelisted]
    end
  end

end; end
