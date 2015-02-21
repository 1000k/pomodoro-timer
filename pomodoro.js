angular.module('pomodoroTimer', [])
  .controller('PomodoroController', ['$scope', '$rootScope', '$interval',
    function($scope, $rootScope, $interval) {
      var TIME_WORK_MS = 1500000, // 25 min (milliseconds)
        TIME_BREAK_MS = 300000, // 5 min (milliseconds)
        CYCLE_WORK = 'work',
        CYCLE_BREAK = 'break',
        COUNTDOWN_RESOLUTION_MS = 1000, // *NOTE* If less than 1000ms, countdown will stop when the tab is out-focused.
        NOTIFICATION_AUTO_CLOSE_DURATION_MS = 15000,
        stopPromise;

      var Notification = window.Notification || window.mozNotification || window.webkitNotification;

      if (Notification && Notification.permission !== 'granted') {
        Notification.requestPermission(function(permission) {
          // do something
        });
      }

      var showNotification = function(msg) {
        if (Notification && Notification.permission === 'granted') {
          var instance = new Notification(
            "Time Expired", {
              body: msg,
              icon: "data:image/png;base64,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"
            }
          );

          instance.onshow = function() {
            setTimeout(function() {
              instance.close();
            }, NOTIFICATION_AUTO_CLOSE_DURATION_MS);
          };
        }

        return false;
      }

      var updateTimerDisplay = function(ms) {
        var min = Math.floor(ms / 1000 / 60),
          sec = Math.floor(ms / 1000 % 60),
          timerDisplay = ('00' + min).substr(-2) + ':' + ('00' + sec).substr(-2);

        $scope.pomodoro_timer_display = timerDisplay;
        $rootScope.title = $scope.current_cycle + ' ' + timerDisplay;
        return timerDisplay;
      };

      var toggleCycle = function() {
        $scope.current_cycle = ($scope.current_cycle === CYCLE_WORK) ?
          CYCLE_BREAK : CYCLE_WORK;

        switch ($scope.current_cycle) {
          case CYCLE_WORK:
            $scope.pomodoro_timer = TIME_WORK_MS;
            showNotification('Get back to work.');
            break;
          case CYCLE_BREAK:
          default:
            $scope.pomodoro_timer = TIME_BREAK_MS;
            showNotification('Have a break.');
            break;
        }

        $scope.runPomodoro();
      }

      var init = function() {
        $scope.current_cycle = 'work';
        $scope.cycleColor = 'cycle-stop';
        $scope.pomodoro_timer = TIME_WORK_MS;
        $scope.pomodoro_timer_display = updateTimerDisplay($scope.pomodoro_timer);
      };

      $scope.runPomodoro = function() {
        $scope.cycleColor = 'cycle-' + $scope.current_cycle;

        if (angular.isDefined(stopPromise)) return;

        stopPromise = $interval(function() {
          if ($scope.pomodoro_timer > 0) {
            $scope.pomodoro_timer = $scope.pomodoro_timer - COUNTDOWN_RESOLUTION_MS;
            updateTimerDisplay($scope.pomodoro_timer);
          } else {
            toggleCycle();
          }
        }, COUNTDOWN_RESOLUTION_MS);
      };

      $scope.pausePomodoro = function() {
        if (angular.isDefined(stopPromise)) {
          $interval.cancel(stopPromise);
          stopPromise = undefined;
          $scope.cycleColor = 'cycle-stop';
        }
      };

      $scope.resetPomodoro = function() {
        $scope.pausePomodoro();
        init();
      };

      $scope.$on('$destroy', function() {
        // Make sure that the interval is destroyed too
        $scope.pausePomodoro();
      });

      $scope.$watch('$viewContentLoaded', function() {
        init();
      });
    }]);
