window.App =
  Helpers: {}

App.Helpers =
  poll: (url, success, error) ->
    $.post url, (data) =>
      console.log("starting poll")
      if data == "1"
        success()
      else if data == "-1"
        error()
      else
        setTimeout ->
          App.Helpers.poll(url, success, error)
        , 5000
