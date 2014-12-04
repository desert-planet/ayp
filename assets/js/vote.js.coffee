$ ->
  $('.vote').on 'click', (event) ->
    do event.preventDefault
    $this = $(this)
    return unless (comicID = $this.data 'id')
    $counter = $('.number-of-votes')
    count = parseInt $counter.text()
    count = 0 if isNaN(count)

    console.log "Vote on: #{comicID} with #{count} votes so far"

    # TODO: Make a call, then on success
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
        {count} = data
        $counter.text(count)
