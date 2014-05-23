class Sanitize; module Transformers; module CSS

# Enforces a CSS whitelist on the contents of `style` attributes.
class CleanAttribute
  def initialize(config)
    @scss = Sanitize::CSS.new(config)
  end

  def call(env)
    node = env[:node]

    return unless node.type == Nokogiri::XML::Node::ELEMENT_NODE &&
        node.key?('style') && !env[:is_whitelisted]

    attr = node.attribute('style')
    css  = @scss.properties(attr.value)

    if css.strip.empty?
      attr.unlink
    else
      attr.value = css
    end
  end
end

# Enforces a CSS whitelist on the contents of `<style>` elements.
class CleanElement
  def initialize(config)
    @scss = Sanitize::CSS.new(config)
  end

  def call(env)
    node = env[:node]

    return unless node.type == Nokogiri::XML::Node::ELEMENT_NODE &&
        env[:node_name] == 'style'

    css = @scss.stylesheet(node.content)

    if css.strip.empty?
      node.unlink
    else
      node.children.unlink
      node << Nokogiri::XML::Text.new(css, node.document)
    end
  end
end

end; end; end
