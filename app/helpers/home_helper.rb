module HomeHelper
  def link_li(icon, text, href)
    content_tag 'li' do
      link_to href, target: '_blank' do
        content_tag('i', ' ', class: icon) + ' ' + text
      end
    end
  end

  def volmer_avatar
    gravatar_image_tag 'volmerius@gmail.com', class: 'img-circle', gravatar: {size: 200, rating: 'x'}
  end

  def locale_items(default)
    ret = ''

    locales = Volmerius::Application.config.locales

    locales.each do |locale|
      options = {class: 'active'} if default.to_s == locale.last
      ret += content_tag 'li', options do
        link_to locale.first, {locale: locale.last}
      end
    end

    raw ret
  end
end
