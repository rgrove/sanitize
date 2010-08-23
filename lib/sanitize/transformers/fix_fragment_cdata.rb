class Sanitize; module Transformers

  # Nokogiri 1.4.2 and higher contain a fragment parsing bug that causes the
  # string "</body></html>" to be appended to the CDATA inside an unterminated
  # <script> or <style> element. This transformer works around this bug by
  # finding affected elements and removing the spurious text.
  #
  # See http://github.com/tenderlove/nokogiri/issues#issue/315
  FIX_FRAGMENT_CDATA = lambda do |env|
    node_name = env[:node_name]

    if node_name == 'script' || node_name == 'style'
      node = env[:node]

      unless node.children.empty?
        last_child = node.children.last

        if last_child.text? && last_child.content =~ %r|</body></html>$|
          last_child.content = last_child.content.chomp('</body></html>')
        end
      end
    end

    nil
  end

end; end
