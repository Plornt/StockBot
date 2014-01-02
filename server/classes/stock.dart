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
  num totalShares = 0;
  num sharesForSale = 0;
  num currentPrice = 0;
  
  DateTime maxDate;
  num max = 0;
  DateTime minDate;
  num min = 0;
  
  
  Stock._create (this.id) {
    _STOCKS[id] = this;
  }
  
  factory Stock (int ID) { 
    if (_STOCKS.containsKey(ID)) {
      return _STOCKS[ID];
    }
    else return new Stock._create(ID);
  }
  
  Future<StockData> getTimeRange (DateTime timeFrom, DateTime timeTo) {
    
  }
  
  Future<bool> fetchLatestData (TornGetter tg) {
    Completer c = new Completer();
    
    tg.request("http://www.torn.com/stockexchange.php?step=profile&stock=$id").then((data) { 
      Document parsed = parser.parse(data);
      
      try { 
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
  
  Future<bool> insertIntoDb (DatabaseHandler dbh) {
    
  }
  
  
  toJson () {
    return { 'id': id, 'currentPrice':currentPrice, 'acronym': this.acronym, 'name': this.name, 'info': this.info, 'director': this.director, 'marketCap': this.marketCap, 'demand': this.demand, 'totalShares': this.totalShares, 'sharesForSale': this.sharesForSale, 'forecast': this.forecast };
  }
}


class StockData {
  int time = 0;
  num CPS = 0.0;
  int sharesAvailable = 0;  
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