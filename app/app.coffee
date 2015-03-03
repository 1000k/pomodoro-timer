'use strict'

###*
 # @ngdoc overview
 # @name pomodoroTimer
 # @description
 # # pomodoroTimer
 #
 # Main module of the application.
###
angular.module 'pomodoroTimer', []

  .controller 'PomodoroController', ['$scope', '$rootScope', '$interval', ($scope, $rootScope, $interval) ->
    TIME_WORK_MS = 1500000  # 25 min (milliseconds)
    TIME_BREAK_MS = 300000  # 5 min (milliseconds)
    CYCLE_WORK = 'work'
    CYCLE_BREAK = 'break'
    COUNTDOWN_RESOLUTION_MS = 100
    NOTIFICATION_AUTO_CLOSE_DURATION_MS = 15000
    AUDIOS = 
      START: 'assets/audio/start.m4a'
      PAUSE: 'assets/audio/pause.m4a'
      WORK: 'assets/audio/work.m4a'
      BREAK: 'assets/audio/break.m4a'
    stopPromise = undefined
    currentCycle = undefined
    dtStart = dtDist = undefined
    remaingTimeMs = 0
    isRunning = false

    Notification = window.Notification || window.mozNotification || window.webkitNotification

    if Notification and Notification.permission != 'granted'
      Notification.requestPermission (permission) ->
        # do nothing

    showNotification = (msg) ->
      # Show HTML5 Desktop Notification if supported by the browser
      if Notification and Notification.permission == 'granted'
        instance = new Notification(
          "Time Expired", {
            body: msg
            icon: "data:image/pngbase64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADe0lEQVRYR61X23XaQBAFm//YFYRUEKggwphvOxUEKgiuwLgC4wqCKwh884iowKQDUkHg34bcu2dGZ7RaCSmJztGRtDuze+fOY0f1WuC6vr4eYvgL7pZMx8fjcbpcLp9C8v6Y6N9gPJK5DfTH0H/2Zet2IIqii0aj8cNs7MtvXl9fO3Ec70JA/kY/BaDb7W7q9frHAitnmBsvFos4hzlaTPZofd61gX5bJxMAQtujrwXqfuEeHQ6HaZ7lvg6ZODs7u8U9xtw7fx5rDVar1YTjCYAc6x9A+Vg37vV6LYDR2LgwrtrgnW6JweBsPp/zuyYuISP3HoiEBcvA0QjtsVCkC11dXfXxfY+7WUBtMgWQW3yMNOgEON2WsAE3uL0zAKD88+3tLaLVsKCJoPxGYwIb7zHmLBUmMlSTETA4wFpbsnF+fk6GXIyFABBhCwpNbo6YiADmOxRItV5r+G8Sigfj9z6EP6kC1tghFjpkUwwiaLrAGWVjgEGzpSA3xxzT0V1kBUCGedHvsyPgxzaj8N7m2nQHDGjCPdMUAF2EKEHVi1qOzZ/hkmHZDDDrkHKCYNDSiB3WadMdFnCqDnAC6OkKRyE3B1JSmrkg54JWfRmS4Riya6Ig8BlDvpMLgNEONzDoHO0ajP8CwA8+rPtZ6c+4AGi3QPteNuwU+bwsA8JqhKeLKaYoAHxQoxIXSK6+yMRaozSP2ioAfNdqQKYYgPUMmK8ctKXyfwGw7sWaDzBwlAJggw+14PJU1FdlQMryb5/h0FmwBzpbfIIkVAUgbuB5wYpZeBac9L8sVioNLXrLcu5ZAIVKAPJiJFQfCgHoccyKhTS5zFtYx9UFFQE4F7DGYA/X7tnTMMa3q4BlgvAUQH++TBBWSsOqAE6moVeIMjW76oa+vPV/sBBRoUoprgLIHu/sMeH/puqnTkOPpsIWvCwAv1UvPIwkv5NghPAEaAdlNwvJecdxJsUz/YBpm1yPRxA4lu9OleZQ1KMheYS/+zK3R3a1TjYkwkKEZ9KS4Z193F2Vlgzy/MfQX7uaDTwLNsOATkrgsG+z3S7/EcnIzGdEGo8bsZgG6JVq8X2mcgFQUNwxwWvS5eoCrJjYzLXleG953bOKrUF736e9FANWSH5MRqZbCsVbMsZUw8fQtl55CoUM+EpSrG5JDja50LZb2nb9NZvqH1UhSpn8AzxCRT9SmYAVAAAAAElFTkSuQmCC"
          }
        )

        instance.onshow = ->
          setTimeout(
            -> instance.close(),
            NOTIFICATION_AUTO_CLOSE_DURATION_MS
          )

      return false

    playAudio = (audioType) ->
      new Audio(audioType).play()

    updateBackground = (cycle) ->
      $scope.cycleColor = "cycle-#{cycle}"

    updateTimerDisplay = (ms, cycle) ->
      min = Math.floor(ms / 1000 / 60)
      sec = Math.floor(ms / 1000 % 60)
      timerDisplay = if (ms < 0) then '00:00' else timerDisplay = ('00' + min).substr(-2) + ':' + ('00' + sec).substr(-2)

      $scope.indicator = {cycle: cycle, time: timerDisplay}
      $rootScope.title = "#{cycle} #{timerDisplay}"

      return timerDisplay

    toggleCycle = ->
      currentCycle = if (currentCycle == CYCLE_WORK) then CYCLE_BREAK else CYCLE_WORK

      switch currentCycle
        when CYCLE_WORK
          showNotification 'Get back to work.'
          playAudio AUDIOS.WORK
          setTargetTime TIME_WORK_MS
        else
          showNotification 'Have a break.'
          playAudio AUDIOS.BREAK
          setTargetTime TIME_BREAK_MS

      updateBackground currentCycle
      tick()

    setTargetTime = (intervalMs) ->
      dtStart = new Date()
      dtDist = new Date(dtStart.getTime() + intervalMs)

    calcRemaingTime = ->
      return dtDist.getTime() - Date.now()

    tick = ->
      remaingTimeMs = calcRemaingTime()
      updateTimerDisplay remaingTimeMs, currentCycle

    init = ->
      isRunning = false
      currentCycle = CYCLE_WORK
      updateBackground 'stop'
      remaingTimeMs = TIME_WORK_MS
      updateTimerDisplay remaingTimeMs, currentCycle

    $scope.runPomodoro = ->
      updateBackground currentCycle

      if angular.isDefined stopPromise then return

      if !isRunning
        setTargetTime TIME_WORK_MS
        isRunning = true

      playAudio AUDIOS.START

      stopPromise = $interval ->
        if remaingTimeMs > 0
          tick()
        else
          toggleCycle()
      , COUNTDOWN_RESOLUTION_MS

    $scope.pausePomodoro = ->
      if angular.isDefined stopPromise
        $interval.cancel stopPromise
        stopPromise = undefined
        playAudio AUDIOS.PAUSE
        updateBackground 'stop'

    $scope.resetPomodoro = ->
      $scope.pausePomodoro()
      init()

    $scope.$on '$destroy', ->
      # Make sure that the interval is destroyed too
      $scope.pausePomodoro()

    $scope.$watch '$viewContentLoaded', ->
      init()
  ]

  .directive 'ptIndicator', ->
    return {
      restrict: 'E'
      scope: {
        indicator: '='
      }
      templateUrl: 'app/indicator.tpl.html'
    }

