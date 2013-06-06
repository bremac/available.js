#
#

DAYS = [
  {name: "Sun", dayId: 0},
  {name: "Mon", dayId: 1},
  {name: "Tue", dayId: 2},
  {name: "Wed", dayId: 3},
  {name: "Thu", dayId: 4},
  {name: "Fri", dayId: 5},
  {name: "Sat", dayId: 6},
]

HOURS = [0 .. 23]

twelveHourTime = (hour) ->
  if hour % 12 == 0
    "12:00"
  else
    "#{hour % 12}:00"


class Available
  constructor: (options) ->
    {$parent, @days, @hours, @onChanged} = options
    @days ?= DAYS
    @hours ?= HOURS
    @onChanged ?= null

    @cells = {}
    @activeCell = null

    @$el = $('<table class="available"></table>')
    @addHeader(@$el)
    @addBody(@$el)
    @addFooter(@$el)

    $parent.append(@$el)

  addHeader: ($el) ->
    $tr = $("<tr><th></th></tr>").appendTo($el)
    for {name} in @days
      $("<th>#{name}</td>").appendTo($tr)
    null

  addBody: ($el) ->
    for startHour in @hours
      $tr = $("<tr></tr>").appendTo($el)

      if startHour == 11
        $tr.addClass("pre-noon")
      if startHour == 12
        $tr.addClass("post-noon")

      $("<td>#{twelveHourTime(startHour)}</td>").appendTo($tr)

      for _, x in DAYS
        cell =
          $el: $("<td></td>").appendTo($tr)
          x: x
          startHour: startHour
          isActive: false

        do (cell) =>
          cell.$el.click (e) =>
            if @activeCell == null
              @activeCell = cell
            else
              @toggleCells(@activeCell, cell)
              @activeCell = null

          cell.$el.mousemove (e) =>
            if @activeCell != null
              @toggleCellsTentative(@activeCell, cell)

        @cells[x] ?= {}
        @cells[x][startHour] = cell

    null

  addFooter: ($el) ->
    endHour = @hours[@hours.length - 1] + 1
    $tr = $('<tr class="trailing-row"></tr>').appendTo($el)
    $("<td>#{twelveHourTime(endHour)}</td>").appendTo($tr)
    null

  forCells: (fromCell, toCell, fxn) ->
    for x in [fromCell.x .. toCell.x]
      for startHour in [fromCell.startHour .. toCell.startHour]
        fxn(@cells[x][startHour])
    null

  clearTentative: () ->
    @$el.find('.tentative-interval').removeClass('tentative-interval')
    null

  clearActive: () ->
    @$el.find('.available-interval').removeClass('available-interval')
    for _, column of @cells
      for _, cell of column
        cell.isActive = false
    null

  markActive: (cell, isNowActive) ->
    cell.isActive = isNowActive
    cell.$el.toggleClass('available-interval', isNowActive)
    null

  toggleCells: (fromCell, toCell) ->
    @clearTentative()
    isNowActive = not fromCell.isActive

    @forCells fromCell, toCell, (cell) =>
      @markActive(cell, isNowActive)

    @triggerChanged()
    null

  toggleCellsTentative: (fromCell, toCell) ->
    @clearTentative()
    isNowActive = not fromCell.isActive

    @forCells fromCell, toCell, (cell) ->
      cell.$el.addClass('tentative-interval')
    null

  triggerChanged: () ->
    if @onChanged == null
      return
    availableIntervals = @serialize()
    @onChanged(availableIntervals)
    null

  serialize: () ->
    availableIntervals = []
    for {dayId}, x in @days
      lastInterval = null

      for startHour in @hours
        cell = @cells[x][startHour]
        if lastInterval == null and cell.isActive
          lastInterval =
            dayId: dayId
            startHour: startHour
            endHour: startHour + 1
        else if lastInterval != null and cell.isActive
          lastInterval.endHour += 1
        else if lastInterval != null and not cell.isActive
          availableIntervals.push(lastInterval)
          lastInterval = null

      if lastInterval != null
        availableIntervals.push(lastInterval)

    availableIntervals

  deserialize: (availableIntervals) ->
    @clearTentative()
    @clearActive()

    xForDayId = {}
    for {dayId}, x in @days
      xForDayId[dayId] = x

    for {dayId, startHour, endHour} in availableIntervals
      x = xForDayId[dayId]
      for hour in [startHour ... endHour]
        cell = @cells[x][hour]
        @markActive(cell, true)

    @triggerChanged()
    null


window.Available = Available
