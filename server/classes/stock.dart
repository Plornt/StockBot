part of StockBot;

class Stock {
  static Map<int, Stock> _STOCKS = new Map<int, Stock>();
  
  int id = 0;
  bool _init  = false;
  bool _errored = false;
  
  String acronym = "";
  String name = "";
  String info = "";
  String director = "";
  String marketCap = "";
  String demand = "";
  String forecast = "";
  String benefit = "";
  num benefitShares = 0;
  num totalShares = 0;
  num sharesForSale = 0;
  num currentPrice = 0;
  
  DateTime maxDate;
  num max = 0;
  DateTime minDate;
  num min = 0;
  bool updatedStockPrice = false;
  DateTime lastUpdate;
  
  Stock._create (this.id) {
    _STOCKS[id] = this;
  }
  
  factory Stock (int ID) { 
    if (_STOCKS.containsKey(ID)) {
      return _STOCKS[ID];
    }
    else return new Stock._create(ID);
  }
  
  Future<TimedStockData> getTransactionsBackFrom (DatabaseHandler dbh, Duration timeOffset) {
    DateTime now = new DateTime.now();
    DateTime timeSince = new DateTime.fromMillisecondsSinceEpoch((now.millisecondsSinceEpoch - (now.millisecondsSinceEpoch % 900000)) - timeOffset.inMilliseconds);
    return getTimeRange(dbh, timeSince);
  }
  
  // TODO: PROPER CACHING OF STOCK DATA SO IT CAN PEICE TOGETHER USING OTHER CACHES RATHER THAN REQUERYING.
  Future<TimedStockData> getTimeRange (DatabaseHandler dbh, DateTime timeFrom, [DateTime timeTo]) {
    Completer<TimedStockData> c = new Completer();
    if (TimedStockData.exists(this.id, timeFrom, timeTo)) {
      c.complete(TimedStockData.get(this.id, timeFrom, timeTo));
    }
    else {
      dbh.prepareExecute("SELECT updateTime, cost, sharesForSale FROM stockprices WHERE stock_id=? AND updateTime >= ? AND updateTime <= ?",[id, timeFrom.millisecondsSinceEpoch, (timeTo != null ? timeTo.millisecondsSinceEpoch : new DateTime.now().millisecondsSinceEpoch)])
        .then((Results res) {
          TimedStockData tsd = new TimedStockData(id, timeFrom, timeTo);
          List<StockData> dat = new List<StockData>();
          print("Retreiving Data");
          res.listen((Row data) {
            print("A row!");
            dat.add(new StockData(new DateTime.fromMillisecondsSinceEpoch(data[0]), data[1], data[2]));
          }).onDone(() { 
            tsd._data = dat;
            print("Added data ${dat.length}");
            c.complete(tsd);
          });
        });
    }
    return c.future;
  }
  
  Future<bool> fetchLatestData (TornGetter tg) {
    Completer c = new Completer();
    
    tg.request("http://www.torn.com/stockexchange.php?step=profile&stock=$id").then((data) { 
      Document parsed = parser.parse(data);
      
      try { 
        updatedStockPrice = false;
        this.currentPrice =  num.parse(childQuerySelector(parsed.body, STOCK_SELECTORS.STOCK_COST)[0].innerHtml.replaceAll(",", "").replaceAll(r"$", ""), (e) { return 0; });
        this.acronym = childQuerySelector(parsed.body, STOCK_SELECTORS.ACRONYM)[0].innerHtml;    
        this.name = childQuerySelector(parsed.body, STOCK_SELECTORS.NAME)[0].innerHtml;  
        this.info = childQuerySelector(parsed.body, STOCK_SELECTORS.INFO)[0].innerHtml;  
        this.director = childQuerySelector(parsed.body, STOCK_SELECTORS.DIRECTOR)[0].innerHtml;  
        this.marketCap = childQuerySelector(parsed.body, STOCK_SELECTORS.MARKET_CAP)[0].innerHtml;  
        this.demand = childQuerySelector(parsed.body, STOCK_SELECTORS.DEMAND)[0].innerHtml;
        this.totalShares = num.parse(childQuerySelector(parsed.body, STOCK_SELECTORS.TOTAL_SHARES)[0].innerHtml.replaceAll(",", ""), (e) { return 0; });
        this.sharesForSale = num.parse(childQuerySelector(parsed.body, STOCK_SELECTORS.SHARES_FOR_SALE)[0].innerHtml.replaceAll(",", ""), (e) { return 0; });
        this.forecast = childQuerySelector(parsed.body, STOCK_SELECTORS.FORECAST)[0].innerHtml;
  
        c.complete(true);
      }
      catch (e) {        
        c.completeError(e);
        this._errored = true;
      }
    }).catchError(c.completeError);
    return c.future;
  }
  
  Future<bool> updateDB (DatabaseHandler dbh) {
    Completer c = new Completer();
    Future.wait([updateInfoDatabase(dbh), updateQuarterHourStockPrices(dbh)]).then((List<bool> vals) { 
      c.complete(vals.every((e) { return e == true; }));
    });
    return c.future;
  }
  Future<bool> updateInfoDatabase (DatabaseHandler dbh) { 
    Completer c = new Completer();
    dbh.prepareExecute("INSERT INTO general (stock_id, acro, name, benefit, benefit_shares, min, minDate, max, maxDate, lastUpdate, info, currentCost, sharesForSale, totalShares)"
                        " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE acro= VALUES(acro), name = VALUES(name), benefit = VALUES(benefit), benefit_shares = VALUES(benefit_shares), "
                        "min = VALUES(min), minDate = VALUES(minDate), max = VALUES(max), maxDate = VALUES(maxDate), lastUpdate = VALUES(lastUpdate), info = VALUES(info), currentCost = VALUES(currentCost), sharesForSale = VALUES(sharesForSale), totalShares = VALUES(totalShares)"
        ,[id, acronym, name, benefit, benefitShares, min, minDate.millisecondsSinceEpoch, max, maxDate.millisecondsSinceEpoch, lastUpdate.millisecondsSinceEpoch, info, currentPrice, sharesForSale, totalShares]).then((Results res) { 
          if (res.affectedRows < 3) {
            c.complete(true);
          }
          else {
            c.completeError("Affected Rows: ${res.affectedRows}");
          }
        }).catchError(c.completeError);
    
    return c.future;
  }
  Future<bool> updateQuarterHourStockPrices (DatabaseHandler dbh) {
    Completer c = new Completer();
    if (updatedStockPrice == false) {
      DateTime now = new DateTime.now();
      DateTime prev15Mins = new DateTime.fromMillisecondsSinceEpoch((now.millisecondsSinceEpoch - (now.millisecondsSinceEpoch % 900000)));
      TimedStockData._cache.forEach((String key, TimedStockData data) { 
        List<String> splitKey = key.split(":");
        if (id.toString() == key[0]) {
          if (key[2] == "true") {
            data._data.add(new StockData(prev15Mins, currentPrice, sharesForSale));
          }
        }
      });
      dbh.prepareExecute("SELECT COUNT(*) FROM stockprices WHERE stock_id = ? AND updateTime >= ?", [id, prev15Mins.millisecondsSinceEpoch]).then((Results res) { 
        res.first.then((Row row) { 
          if (row[0] == 0) {
            dbh.prepareExecute("INSERT INTO stockprices (stock_id, cost, totalShares, sharesForSale, updateTime) VALUES (?, ?, ?, ?, ?)",[id, currentPrice, totalShares, sharesForSale, prev15Mins.millisecondsSinceEpoch]).then((Results res) { 
              if (res.insertId != null) {
                updatedStockPrice = true;
                c.complete(true);
              }
              else {
                c.completeError("Didnt insert");
              }
            });
          }
          else c.complete(true);
        });
      });
    }
    else c.complete(true);
    return c.future;
  }
 
  toJson () {
    return { 'id': id, 'currentPrice':currentPrice, 'acronym': this.acronym, 'name': this.name, 'info': this.info, 'director': this.director, 'marketCap': this.marketCap, 'demand': this.demand, 'totalShares': this.totalShares, 'sharesForSale': this.sharesForSale, 'forecast': this.forecast };
  }
  
  static Future<bool> init (DatabaseHandler dbh) {
    Completer c = new Completer();
    dbh.query("SELECT stock_id, acro, name, benefit, benefit_shares, min, minDate,max, maxDate, lastUpdate, info, currentCost, sharesForSale, totalShares FROM `general`").then((Results res) { 
                res.listen((Row stockRow) { 
                  Stock s = new Stock(stockRow[0]);
                  s.acronym = stockRow[1].toString();
                  s.name = stockRow[2].toString();
                  s.benefit = stockRow[3].toString();
                  s.benefitShares = stockRow[4];
                  s.min = stockRow[5];
                  s.minDate = new DateTime.fromMillisecondsSinceEpoch(stockRow[6] == null ? 0 : stockRow[6]);
                  s.max = stockRow[7];
                  s.maxDate = new DateTime.fromMillisecondsSinceEpoch(stockRow[8] == null ? 0 : stockRow[6]);
                  s.lastUpdate = new DateTime.fromMillisecondsSinceEpoch(stockRow[9] == null ? 0 : stockRow[6]);
                  s.info = stockRow[10].toString();
                  s.currentPrice = stockRow[11];
                  s.sharesForSale = stockRow[12];
                  s.totalShares = stockRow[13];
                }).onDone(() { 
                  c.complete(true);
                });
              });
    return c.future;
  }
}

class TimedStockData {
  static Map<String, TimedStockData> _cache = new Map<String, TimedStockData>();
  DateTime timeFrom;
  DateTime timeTo;
  bool flexible = false;
  List<StockData> _data = new List<StockData>();
  Timer _destroyer;
  int stockID = 0;
  String key = "";
  
  List<StockData> get data {
    if (_destroyer != null) {
      _destroyer.cancel();
    }
    _destroyer = new Timer(new Duration(minutes: 15), this.destroy);
    return _data;
  }
  
  void destroy () {
    _cache.remove(key);
  }
  
 
  TimedStockData._create (int this.stockID, DateTime this.timeFrom, { DateTime this.timeTo, bool this.flexible }) {
    this.key = createKey (stockID, timeFrom, timeTo);
    _cache[key] = this;
    _destroyer = new Timer(new Duration(minutes: 60), this.destroy);
  }
    
  factory TimedStockData (int stockID, DateTime timeFrom, [DateTime timeTo]) {
    String key = createKey (stockID, timeFrom, timeTo);
    if (_cache.containsKey(key)) {
        return _cache[key];
    }
    else return new TimedStockData._create(stockID, timeFrom, timeTo: timeTo, flexible: (timeTo == null ? true : false));
  }
  
  static String createKey (int stockID, DateTime timeFrom, [DateTime timeTo]) {
    return "$stockID:${timeFrom.millisecondsSinceEpoch}:${timeTo != null ? timeTo.millisecondsSinceEpoch : true}";
  }
  static bool exists (int stockID, DateTime timeFrom, [DateTime timeTo]) {
    return _cache.containsKey(createKey (stockID, timeFrom, timeTo));
  }
  static TimedStockData get (int stockID, DateTime timeFrom, [DateTime timeTo]) {
    return _cache[createKey (stockID, timeFrom, timeTo)];
  }
  toJson () {
    return { 'stockID': stockID, 'timeFrom': timeFrom.millisecondsSinceEpoch, 'timeTo': (this.flexible == true ? new DateTime.now().millisecondsSinceEpoch : timeTo.millisecondsSinceEpoch), 'flexible': flexible, 'data': _data };
  }
}
class StockData {
  DateTime time;
  num CPS = 0.0;
  num sharesAvailable = 0;  
  StockData (DateTime this.time, num this.CPS, num this.sharesAvailable);
  toJson () {
    return { 'time': time.millisecondsSinceEpoch, 'cps': CPS, 'avail': sharesAvailable };
  }
}


class STOCK_SELECTORS { 
  static const String STOCK_COST = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(0) > TD:eq(1)";
  static const String ACRONYM = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR > TD:eq(1)";
  static const String NAME = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > CENTER:eq(0) > FONT:eq(0) > B:eq(0)";
  static const String INFO = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0)";
  static const String DIRECTOR = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR:eq(2) > TD:eq(1)";
  static const String MARKET_CAP = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(2) > TD:eq(1)";
  static const String DEMAND = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(0) > TABLE > TBODY > TR:eq(6) > TD:eq(1)";    
  static const String TOTAL_SHARES = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(4) > TD:eq(1)";
  static const String SHARES_FOR_SALE = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(6) > TD:eq(1)";
  static const String FORECAST = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR:eq(4) > TD:eq(1)";
}