#
#

ESCAPE_KEYCODE = 27

DEFAULT_DAYS = [
  {name: "Sun", dayId: 0},
  {name: "Mon", dayId: 1},
  {name: "Tue", dayId: 2},
  {name: "Wed", dayId: 3},
  {name: "Thu", dayId: 4},
  {name: "Fri", dayId: 5},
  {name: "Sat", dayId: 6},
]

DEFAULT_TIMES = (i * 30 for i in [17 .. 33])


timeFromMinuteOfDay = (minuteOfDay) ->
  hour = Math.floor(minuteOfDay / 60)
  minute = minuteOfDay % 60
  [hour, minute]


twelveHourTime = (hour, minute) ->
  minuteString = "00#{minute}".slice(-2)
  hourString = if hour % 12 == 0 then "12" else "#{hour % 12}"
  "#{hourString}:#{minuteString}"


class Available
  constructor: (options) ->
    {$parent, @days, times, @onChanged} = options
    @days ?= DEFAULT_DAYS
    times ?= DEFAULT_TIMES
    @allTimes = times
    @times = times[0...-1]
    @lastTime = times[times.length - 1]
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
    for startTime in @times
      $tr = $("<tr></tr>").appendTo($el)

      [hour, minute] = timeFromMinuteOfDay(startTime)

      $label = $("<td><span>#{twelveHourTime(hour, minute)}</span></td>")
      $label.addClass("label hour-#{hour} minute-#{minute}")
      $label.appendTo($tr)

      for {dayId}, column in @days
        $td = $("<td></td>")
        $td.addClass("cell day-#{dayId} hour-#{hour} minute-#{minute}")
        $td.appendTo($tr)

        @cells[column] ?= {}
        @cells[column][startTime] = {
          $el: $td,
          column: column,
          startTime: startTime,
          isActive: false,
        }

    null

  addFooter: ($el) ->
    [hour, minute] = timeFromMinuteOfDay(@lastTime)
    $tr = $('<tr class="trailing-row"></tr>').appendTo($el)
    # TODO: Factor this out
    $label = $("<td><span>#{twelveHourTime(hour, minute)}</span></td>")
    $label.addClass("label hour-#{hour} minute-#{minute}")
    $label.appendTo($tr)
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
    fromTime = fromCell.startTime
    toTime = toCell.startTime

    if toTime < fromTime
      [fromTime, toTime] = [toTime, fromTime]

    for column in [fromCell.column .. toCell.column]
      for _, cell of @cells[column]
        if fromTime <= cell.startTime <= toTime
          fxn(cell)

    null

  clearTentative: () ->
    tentativeClasses = 'tentative tentative-addition tentative-removal'
    @$el.find('.tentative').removeClass(tentativeClasses)
    null

  clearActive: () ->
    @$el.find('.marked-interval').removeClass('marked-interval')
    for _, column of @cells
      for _, cell of column
        cell.isActive = false
    null

  markActive: (cell, isNowActive) ->
    cell.isActive = isNowActive
    cell.$el.toggleClass('marked-interval', isNowActive)
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
    tentativeStateClass = if isNowActive
      "tentative-addition"
    else
      "tentative-removal"
    tentativeClass = "tentative #{tentativeStateClass}"

    @forCells fromCell, toCell, (cell) ->
      cell.$el.addClass(tentativeClass)
    null

  triggerChanged: () ->
    if @onChanged == null
      return
    markedIntervals = @serialize()
    @onChanged(markedIntervals)
    null

  serialize: () ->
    markedIntervals = []
    for {dayId}, column in @days
      lastInterval = null

      for i in [0 ... @allTimes.length-1]
        startTime = @allTimes[i]
        endTime = @allTimes[i + 1]
        cell = @cells[column][startTime]
        if lastInterval == null and cell.isActive
          lastInterval = {
            dayId: dayId,
            startTime: startTime,
            endTime: endTime,
          }
        else if lastInterval != null and cell.isActive
          lastInterval.endTime = endTime
        else if lastInterval != null and not cell.isActive
          markedIntervals.push(lastInterval)
          lastInterval = null

      if lastInterval != null
        markedIntervals.push(lastInterval)

    markedIntervals

  deserialize: (markedIntervals) ->
    @clearTentative()
    @clearActive()

    columnForDayId = {}
    for {dayId}, column in @days
      columnForDayId[dayId] = column

    for {dayId, startTime, endTime} in markedIntervals
      column = columnForDayId[dayId]
      for time in @times
        if startTime <= time < endTime
          cell = @cells[column][time]
          @markActive(cell, true)

    null


window.Available = Available
