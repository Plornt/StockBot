part of StockBotClient;

@NgController(
    selector: '[loading]',
    publishAs: 'loader'
)
class Loading {
  bool loaded = false;
  Loading () {

      getRequest("/Session/Get").then((HttpRequest req) { 
        JsonData sess = new JsonData(req.responseText);
        if (sess.getBool("loggedIn")) {
          JsonData data = sess.getJsonDataMap("user");
          if (data != null) {
            User tempU = new User(data.getNum("userID"), data.getString("username"), new DateTime.fromMillisecondsSinceEpoch(data.getNum("creationDate"), isUtc: true), new DateTime.fromMillisecondsSinceEpoch(data.getNum("lastLogin"), isUtc: true),
                data.getBool("active"), data.getBool("isAdmin"), data.getBool("apiAllowed"), data.getString("lastIp"), data.getString("apiKey"), data.getNum("tornID"));
            StockBotModule.user = tempU;
            StockBotModule.loggedIn = true;
            if (StockBotModule.loadedStocks != true) {
              StockBotModule.loadedStocks = true;
              getRequest("/StockInfo/GenericData").then((HttpRequest req) {
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
                    StockBotModule.stocks.add(tStock);
                  });
                  loaded = true;
                }
              });
            }
            else loaded = true;
          }
          else loaded = true;
        }
        else loaded = true;
      });
    }
}
