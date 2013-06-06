#
#

DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

twelveHourTime = (hour) ->
  if hour % 12 == 0
    "12:00"
  else
    "#{hour % 12}:00"


class Available
  constructor: ($parent) ->
    @$el = $('<table class="available"></table>')
    @addHeader(@$el)
    @addBody(@$el)
    @addFooter(@$el)
    $parent.append(@$el)

  addHeader: ($el) ->
    $tr = $("<tr><th>&nbsp;</th></tr>").appendTo($el)
    for day in DAYS
      $("<th>#{day}</td>").appendTo($tr)

  addBody: ($el) ->
    for hour in [0..23]
      $tr = $("<tr></tr>").appendTo($el)

      if hour == 11
        $tr.addClass("pre-noon")
      if hour == 12
        $tr.addClass("post-noon")

      $("<td>#{twelveHourTime(hour)}</td>").appendTo($tr)

      for _ in DAYS
        $("<td>&nbsp;</td>").appendTo($tr)

  addFooter: ($el) ->
    $('<tr class="trailing-row"><td>12:00</td></tr>').appendTo($el)


window.Available = Available
