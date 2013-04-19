module HomeHelper
  def link_li(icon, text, href)
    content_tag 'li' do
      link_to href, target: '_blank' do
        content_tag('i', ' ', class: icon) + ' ' + text
      end
    end
  end
end
