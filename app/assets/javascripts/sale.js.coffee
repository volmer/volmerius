$ ->
  $('#image-modal').on 'show.bs.modal', (e)->
    item = $(e.relatedTarget).closest('.panel').attr('id')
    image_path = "/assets/sale/#{item}.jpg"
    $(@).find('img').attr('src', image_path)

  $('.merchandise-image').each ->
    item = $(@).closest('.panel').attr('id')
    image_url = "url('/assets/sale/#{item}.jpg')"
    $(@).css('background-image', image_url)
