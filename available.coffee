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
    @cells = {}
    @activeCell = null
    @addHeader(@$el)
    @addBody(@$el)
    @addFooter(@$el)
    $parent.append(@$el)

  addHeader: ($el) ->
    $tr = $("<tr><th>&nbsp;</th></tr>").appendTo($el)
    for day in DAYS
      $("<th>#{day}</td>").appendTo($tr)

  addBody: ($el) ->
    for hour in [0 .. 23]
      $tr = $("<tr></tr>").appendTo($el)

      if hour == 11
        $tr.addClass("pre-noon")
      if hour == 12
        $tr.addClass("post-noon")

      $("<td>#{twelveHourTime(hour)}</td>").appendTo($tr)

      for _, x in DAYS
        cell =
          $el: $("<td>&nbsp;</td>").appendTo($tr)
          x: x
          y: hour
          isActive: false

        do (cell) =>
          cell.$el.click (e) =>
            if @activeCell == null
              @activeCell = cell
            else
              @toggleCells(@activeCell, cell)
              @activeCell = null

          cell.$el.mousemove (e) =>
            if @activeCell == null
              return
            @toggleCellsTentative(@activeCell, cell)

        @cells[x] ?= {}
        @cells[x][hour] = cell

  addFooter: ($el) ->
    $('<tr class="trailing-row"><td>12:00</td></tr>').appendTo($el)

  forCells: (fromCell, toCell, fxn) ->
    for x in [fromCell.x .. toCell.x]
      for y in [fromCell.y .. toCell.y]
        fxn(@cells[x][y])

  toggleCells: (fromCell, toCell) ->
    $('.tentative-interval').removeClass('tentative-interval')
    isNowActive = not fromCell.isActive

    @forCells fromCell, toCell, (cell) ->
      cell.isActive = isNowActive
      cell.$el.toggleClass('available-interval', isNowActive)

  toggleCellsTentative: (fromCell, toCell) ->
    $('.tentative-interval').removeClass('tentative-interval')
    isNowActive = not fromCell.isActive

    @forCells fromCell, toCell, (cell) ->
      cell.$el.addClass('tentative-interval')


window.Available = Available
