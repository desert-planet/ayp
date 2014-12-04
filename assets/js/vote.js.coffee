$ ->
  $('.vote').on 'click', (event) ->
    do event.preventDefault
    return unless (comicID = $(this).data 'id')
    $counter = $('.number-of-votes')
    count = parseInt $counter.text()
    count = 0 if isNaN(count)

    console.log "Vote on: #{comicID} with #{count} votes so far"

    # TODO: Make a call, then on success
    do ->
      count += 1
      $counter.text count
