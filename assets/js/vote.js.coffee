$ ->
  $('.vote').on 'click', (event) ->
    do event.preventDefault
    $this = $(this)
    $counter = $('.number-of-votes') # TODO: Scope the search to $this

    return unless (comicID = $this.data 'id')
    count = parseInt $counter.text()
    count = 0 if isNaN(count)

    $.ajax "/vote/#{comicID}/",
      type: 'POST'
      headers: {'Content-Type': 'application/json'}
      data: JSON.stringify(now: Date.now())
      timeout: 10 * 1000

      error: (jxhr, text, err) ->
        $this.addClass 'failed'
        setTimeout((=> $this.removeClass 'failed'), 250)

      success: (data, status, jxhr) ->
        return unless data.count > 0
        $this.addClass 'succeeded'
        setTimeout((=> $this.removeClass 'succeeded'), 250)

        {count} = data
        $counter.text(count)
