class Sanitize; module Transformers

  CleanComment = lambda do |env|
    return if env[:is_whitelisted]

    node = env[:node]
    return unless node.comment? && !env[:config][:allow_comments]

    if env[:config][:escape_only]
      node.replace(Nokogiri::XML::Text.new(node.to_s, node.document))
    else
      node.unlink
    end
  end

end; end
