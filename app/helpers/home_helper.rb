module HomeHelper
  def link_li(icon, text, href)
    content_tag 'li' do
      link_to text, href, target: '_blank'
    end
  end
end
