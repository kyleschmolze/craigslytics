window.App =
  Helpers: {}

App.Helpers =
  poll: (url, success) ->
    $.post url, (data) =>
      if data == "1"
        success()
      else
        console.log 're-enqueuing'
        setTimeout ->
          App.Helpers.poll(url, success)
        , 5000
