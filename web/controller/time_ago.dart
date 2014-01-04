part of StockBotClient;


@NgFilter(name: 'duration')
class DurationFilter {
  call(num, [maxDet]) {
    if (num != null && num is int) {
      int maxDetail = 4;
      if (maxDet != null && maxDet is int) {
        maxDetail = maxDet;
      }
      DateTime currentUtcTime = new DateTime.now();
      int offset = currentUtcTime.millisecondsSinceEpoch - num;
      Duration offsetDuration = new Duration(milliseconds: offset);
      StringBuffer timeAgo = new StringBuffer();
      if (offsetDuration.inDays > 0 || maxDetail == 1) {
        timeAgo.write(offsetDuration.inDays);
        timeAgo.write(" day");
        if (offsetDuration.inDays > 1) timeAgo.write("s");
        timeAgo.write(", ");
      }
      
      if ((offsetDuration.inHours % 24) > 0 || maxDetail == 2) {
        timeAgo.write((offsetDuration.inHours % 24) % 24);
        timeAgo.write(" hour");
        if (offsetDuration.inHours > 1) timeAgo.write("s");
        timeAgo.write(", ");
      }
      if ((offsetDuration.inMinutes % 60) > 0 || maxDetail == 3) {
        timeAgo.write(offsetDuration.inMinutes % 60);
        timeAgo.write(" minute");
        if ((offsetDuration.inMinutes % 60) > 1) timeAgo.write("s");
        timeAgo.write(", ");
      }
      if ((offsetDuration.inSeconds % 60) > 0  || maxDetail == 4) {
        timeAgo.write(offsetDuration.inSeconds % 60);
        timeAgo.write(" second");
        if ((offsetDuration.inSeconds % 60) > 1) timeAgo.write("s");
        timeAgo.write(", ");
      }
      
      return timeAgo.toString().substring(0, timeAgo.toString().length - 2);
    }
  }
}

@NgComponent(
    selector: 'ago',
    publishAs: 'time',
    template: '{{time.time}}',
    map: const {
      'last-update': '@lastUpdate',
      'detaillevel': '@detailLevel'
    }
)
class TimeAgo {
  Timer updateDuration;
  int _detailLevel = 4;
  String time = "0 seconds";
  Duration detailTime = new Duration(seconds: 1);
  int _lastUpdate = new DateTime.now().millisecondsSinceEpoch;
  DurationFilter filter = new DurationFilter();
  set detailLevel (String level) {
    if (level != null) { 
      int aL = int.parse(level, onError: (e) { return 4; });
      _detailLevel = aL > 0 && aL < 5 ? aL : 4;
    }
    updateDetailTime();
    startTimerNextInterval();
  }
  
  set lastUpdate (String val) {
    if (val !=null) {
      int aL = int.parse(val, onError: (e) { return new DateTime.now().millisecondsSinceEpoch; });
         _lastUpdate  = aL;
         startTimerNextInterval();
    }
  }
  
  get lastUpdate => _lastUpdate;
  get detailLevel => _detailLevel;
  
  
  TimeAgo(Scope scope) {
    updateDetailTime();
    scope.$on(r"$destroy", () { 
      if (updateDuration != null) {
        updateDuration.cancel();
      }
    });
    
  }
  void startTimer () { 
    if (updateDuration != null) updateDuration.cancel();
    updateDuration = new Timer.periodic(detailTime, (Timer t) { 
      time = filter.call(_lastUpdate, _detailLevel);
    });
  }
  
  // Used to sync up the time changes somewhat perfectly without skipping...
  void startTimerNextInterval() {
    if (updateDuration != null) updateDuration.cancel();
    int now = new DateTime.now().millisecondsSinceEpoch;
    int offset = (detailTime.inMilliseconds - (now % detailTime.inMilliseconds));

    updateDuration = new Timer(new Duration(seconds: 1, milliseconds: offset), () { 
      time = filter.call(_lastUpdate, _detailLevel);
      this.startTimer(); 
      });
  }
  
  void updateDetailTime () {
    switch (detailLevel) {
      case 4: 
        detailTime = new Duration(seconds: 1);
        break;
      case 3:
        detailTime = new Duration(minutes: 1);
        break;
      case 2:
        detailTime = new Duration(hours: 1);
        break;
      case 1:
        detailTime = new Duration(days: 1);
        break;
    }
  }

}