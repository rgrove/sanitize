class Sanitize; module Transformers

  CleanComment = lambda do |env|
    return if env[:is_whitelisted]

    node = env[:node]
    node.unlink if node.comment? && !env[:config][:allow_comments]
  end

end; end
