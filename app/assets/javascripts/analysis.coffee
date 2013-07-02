window.App =
  Helpers: {}

App.Helpers =
  poll: (url, options = {}) ->
    $.get url, (data) =>
      if data.error == "-1"
        options.error(data) if options.error?
      else if data.done == "1"
        options.done(data) if options.done?
      else
        options.success(data) if options.success?
        setTimeout ->
          App.Helpers.poll(url, options)
        , 5000
