part of StockBotClient;

class Stock {
  int id = 0;
  
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
  num prevPrice = 0;
  DateTime maxDate;
  num max = 0;
  DateTime minDate;
  num min = 0;
  num weight = 0;
  num potential = 0;
  bool updatedStockPrice = false;
  DateTime lastUpdate;
  num get wpcombine {
    return ((this.currentPrice - this.min)/(this.max - this.min)) / ((this.max - this.currentPrice) / this.currentPrice);
  }
  num get change { 
    return this.currentPrice - this.prevPrice;
  }
  Stock._create (this.id);
  
  Future<dynamic> getTransactions (DateTime dateFrom, DateTime dateTo) {
    if (!dateFrom.isUtc) dateFrom = dateFrom.toUtc(); 
    if (!dateTo.isUtc) dateTo = dateTo.toUtc();
    getRequest("/StockInfo/PricingData/$id/${dateFrom.millisecondsSinceEpoch}/${dateTo.millisecondsSinceEpoch}").then((HttpRequest reqDat) { 
           print(reqDat.responseText);
    });
  }
  
  
  /// static functions below...
  
  static bool loadedStocks = false;
  static bool loadingStocks = false;
  static List<Stock> get stocks {
    return _STOCKS.values.toList();
  }
  static Map<int, Stock> _STOCKS = new Map<int, Stock>();
  static List<Completer> _stockUpdateQueue = new List<Completer>();

  factory Stock (int stockID) {
    if (_STOCKS.containsKey(stockID)) {
      return _STOCKS[stockID];
    }
    else {
      Stock s = new Stock._create(stockID);
      _STOCKS[stockID] = s;
      return s;
    }
  }
  static bool exists(int stockID) {
    return _STOCKS.containsKey(stockID);
  }
  static Stock get (int stockID) {
    return _STOCKS[stockID];
  }
   
  static Future<Stock> fetchStockData (int stockID) {
    Completer c = new Completer();
    getRequest("/StockInfo/GenericData/$stockID").then((HttpRequest req) {
      JsonData currStock = new JsonData(req.responseText);
      Stock tStock = new Stock(currStock.getNum("id").toInt());   
      tStock.currentPrice = currStock.getNum("currentPrice");
      tStock.acronym = currStock.getString("acronym");
      tStock.name = currStock.getString("name");
      tStock.info = currStock.getString("info");
      tStock.director = currStock.getString("director");
      tStock.marketCap = currStock.getString("marketCap");
      tStock.demand = currStock.getString("demand");
      tStock.lastUpdate = new DateTime.fromMillisecondsSinceEpoch(currStock.getNum("lastUpdate"), isUtc: true);
      tStock.totalShares = currStock.getNum("totalShares");
      tStock.sharesForSale = currStock.getNum("sharesForSale");
      tStock.forecast = currStock.getString("forecast");
      tStock.prevPrice = currStock.getNum("prevPrice");
      tStock.weight = currStock.getNum("weight");
      tStock.potential = currStock.getNum("potential");
      tStock.benefit = currStock.getString("benefit");
      tStock.max = currStock.getNum("max");
      tStock.min = currStock.getNum("min");
      tStock.maxDate = new DateTime.fromMillisecondsSinceEpoch(currStock.getNum("maxDate"), isUtc: true);
      tStock.minDate = new DateTime.fromMillisecondsSinceEpoch(currStock.getNum("minDate"), isUtc: true);
      tStock.benefitShares = currStock.getNum("benefitShares");      
      c.complete(tStock);
    }).catchError(c.completeError);
    return c.future;
  }
  static Future<List<Stock>> fetchAllStockData () {
    Completer c = new Completer();
    if (loadingStocks == false && StockBotModule.loggedIn == true) {
      loadingStocks = true;
      getRequest("/StockInfo/GenericData").then((HttpRequest req) {
        loadingStocks = false;
        dynamic obj = JSON.decode(req.responseText);
        if (obj is List) {
          List<JsonData> jsD = new List<JsonData>();
          obj.forEach((Map data) { 
            JsonData currStock = new JsonData.fromMap(data);
            Stock tStock = new Stock(currStock.getNum("id").toInt());   
            tStock.currentPrice = currStock.getNum("currentPrice");
            tStock.acronym = currStock.getString("acronym");
            tStock.name = currStock.getString("name");
            tStock.info = currStock.getString("info");
            tStock.director = currStock.getString("director");
            tStock.marketCap = currStock.getString("marketCap");
            tStock.demand = currStock.getString("demand");
            tStock.lastUpdate = new DateTime.fromMillisecondsSinceEpoch(currStock.getNum("lastUpdate"), isUtc: true);
            tStock.totalShares = currStock.getNum("totalShares");
            tStock.sharesForSale = currStock.getNum("sharesForSale");
            tStock.forecast = currStock.getString("forecast");
            tStock.prevPrice = currStock.getNum("prevPrice");
            tStock.weight = currStock.getNum("weight");
            tStock.potential = currStock.getNum("potential");
            tStock.benefitShares = currStock.getNum("benefitShares");
            tStock.benefit = currStock.getString("benefit");
            tStock.max = currStock.getNum("max");
            tStock.min = currStock.getNum("min");
            tStock.maxDate = new DateTime.fromMillisecondsSinceEpoch(currStock.getNum("maxDate"), isUtc: true);
            tStock.minDate = new DateTime.fromMillisecondsSinceEpoch(currStock.getNum("minDate"), isUtc: true); 
          });
          loadedStocks = true;
          loadingStocks = false;
          _stockUpdateQueue.forEach((Completer nc) { 
            nc.complete(stocks);
          });
          c.complete(stocks);
          _stockUpdateQueue = new List<Completer>();
        }
        else {
          c.completeError("Value returned by server is not valid");
        }
      }).catchError((E) { 
        c.completeError(E);
        loadingStocks = false;
      });
    }
    else {
      _stockUpdateQueue.add(c);
    }
    return c.future;
  }
}