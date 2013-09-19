#
#

DEFAULT_DAYS = [
  {name: "Sun", dayId: 0},
  {name: "Mon", dayId: 1},
  {name: "Tue", dayId: 2},
  {name: "Wed", dayId: 3},
  {name: "Thu", dayId: 4},
  {name: "Fri", dayId: 5},
  {name: "Sat", dayId: 6},
]

DEFAULT_HOURS = [0 .. 23]

ESCAPE_KEYCODE = 27

twelveHourTime = (hour) ->
  if hour % 12 == 0
    "12:00"
  else
    "#{hour % 12}:00"


class Available
  constructor: (options) ->
    {$parent, @days, @hours, @onChanged} = options
    @days ?= DEFAULT_DAYS
    @hours ?= DEFAULT_HOURS
    @onChanged ?= null

    @cells = {}
    @activeCell = null

    @$el = $('<table class="available"></table>')
    @addHeader(@$el)
    @addBody(@$el)
    @addFooter(@$el)

    @bindEvents()

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

      $("<td><span>#{twelveHourTime(startHour)}</span></td>").appendTo($tr)

      for {dayId}, column in @days
        $td = $("<td></td>")
        $td.addClass("day-#{dayId} hour-#{startHour}")
        $td.appendTo($tr)

        @cells[column] ?= {}
        @cells[column][startHour] = {
          $el: $td,
          column: column,
          startHour: startHour,
          isActive: false,
        }

    null

  addFooter: ($el) ->
    endHour = @hours[@hours.length - 1] + 1
    $tr = $('<tr class="trailing-row"></tr>').appendTo($el)
    $("<td><span>#{twelveHourTime(endHour)}</span></td>").appendTo($tr)
    null

  bindEvents: () ->
    $(document).mouseup (e) =>
      if @activeCell != null
        @clearTentative()
        @activeCell = null

    $(document).keydown (e) =>
      if e.keyCode == ESCAPE_KEYCODE and @activeCell != null
        @clearTentative()
        @activeCell = null

    for _, column of @cells
      for _, cell of column
        do (cell) =>
          cell.$el.mousedown (e) =>
            @activeCell = cell
            e.originalEvent.preventDefault()

          cell.$el.mouseup (e) =>
            if @activeCell != null
              @clearTentative()
              @toggleCells(@activeCell, cell)
              @activeCell = null
              return false

          cell.$el.mousemove (e) =>
            if @activeCell != null
              @toggleCellsTentative(@activeCell, cell)

    null

  forCells: (fromCell, toCell, fxn) ->
    for column in [fromCell.column .. toCell.column]
      for startHour in [fromCell.startHour .. toCell.startHour]
        fxn(@cells[column][startHour])
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
    for {dayId}, column in @days
      lastInterval = null

      for startHour in @hours
        cell = @cells[column][startHour]
        if lastInterval == null and cell.isActive
          lastInterval = {
            dayId: dayId,
            startHour: startHour,
            endHour: startHour + 1,
          }
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

    columnForDayId = {}
    for {dayId}, column in @days
      columnForDayId[dayId] = column

    for {dayId, startHour, endHour} in availableIntervals
      column = columnForDayId[dayId]
      for hour in [startHour ... endHour]
        cell = @cells[column][hour]
        @markActive(cell, true)

    null


window.Available = Available
