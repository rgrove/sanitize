# encoding: utf-8

class Sanitize; module Transformers

  CleanDoctype = lambda do |env|
    return if env[:is_whitelisted]
    env[:node].unlink if env[:node].type == Nokogiri::XML::Node::DTD_NODE
  end

end; end
