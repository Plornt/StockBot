part of StockBotClient;
 
@NgFilter(name: 'paddednumber')
class PaddedFilter {
  call(number, padding) {
    if (padding is int && number != null) {
      String str = number.toString();
      while (str.length < padding) str = "0$str";
      return str;
    }
  }
}
@NgFilter(name: 'commaseparate')
class CommaSeparateFilter {
  call(num) {
    if (num != null && num is String) {
      List<String> spl = num.split("").reversed.toList();
      List<String> newStr = new List<String>();
      int x = 0;
      spl.forEach((String c) {
        newStr.add(c);
        x++;
        if ((x % 3) == 0 && x != spl.length) {
          newStr.add(",");
        }
      });
      return newStr.reversed.toList().join("");
    }
  }
}

@NgController(
    selector: '[stockOverview]',
    publishAs: 'overview'
)
class StockOverview {
  List<Stock> stocks = new List<Stock>();
  bool get loaded => Stock.loadedStocks;
  bool get loading => Stock.loadingStocks;
  
  bool desc = true;
  String sortBy = "id";
  Timer periodicUpdate;
  DateTime lastRefresh;
  
  StockOverview (Scope s) {
     if (StockBotModule.checkLogin()) {   
       lastRefresh = new DateTime.now().toUtc();
       if (Stock.loadedStocks == true) {
         stocks = sort(this.sortBy, Stock.stocks);
       }
       updateStocks ();
       periodicUpdate = new Timer.periodic(new Duration(seconds: 10), this.updateStocks);
       s.$on(r"$destroy", () { 
         if (periodicUpdate != null) periodicUpdate.cancel();
       });
     }
  }
  
  void updateStocks ([Timer t]) {
    Stock.fetchAllStockData().then((List<Stock> fetchedStocks) {
      stocks = sort(this.sortBy, fetchedStocks);
      lastRefresh = new DateTime.now();
    }).catchError((e) { 
      if (t != null) t.cancel();
      
    });
  }
  List<Stock> sort(String colName, List<Stock> tempS) {
    this.sortBy = colName;
    tempS.sort((Stock elem1, Stock elem2) { return elem1.id - elem2.id; });
    switch (colName) {
      case "id":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.id - elem2.id; });
        break;
      case "acronym":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.acronym.compareTo(elem2.acronym); });
        break;
      case "name":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.name.compareTo(elem2.name); });
        break;
      case "currentPrice":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.currentPrice - elem2.currentPrice; });
        break;
      case "change":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.change - elem2.change; });
        break;
      case "lastUpdate":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.lastUpdate.millisecondsSinceEpoch - elem2.lastUpdate.millisecondsSinceEpoch; });
        break;
      case "sharesAvailable":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.sharesForSale - elem2.sharesForSale; });
        break;
      case "totalShares":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.totalShares - elem2.totalShares; });
        break;
      case "forecast":
        tempS.sort((Stock elem1, Stock elem2) { return demandSorter (elem1.forecast) - demandSorter (elem2.forecast); });
        break;
      case "demand":
        tempS.sort((Stock elem1, Stock elem2) { return demandSorter (elem1.demand) - demandSorter (elem2.demand); });
        break;
      case "weight":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.weight - elem2.weight; });
        break;
      case "potential":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.potential - elem2.potential; });
        break;
      case "combined":
        tempS.sort((Stock elem1, Stock elem2) { return elem1.wpcombine - elem2.wpcombine; });
        break;
    }
    if (desc != true) {
      tempS = tempS.reversed.toList();
    }
    return tempS;
  }
  void resort (String colName) {
    if (colName == sortBy) { desc = !desc; }
    else desc = true;
    stocks = this.sort(colName, stocks);
  }
}


int demandSorter (String demand) {
  switch (demand) {
    case "N/A":
      return -1;
      break;
    case "Very Good":
      return 4;
      break;
    case "High":
      return 3;
      break;
    case "Good": 
      return 3;
      break;
    case "Average":
      return 2;
      break;
    case "Poor":
      return 1;
      break;
    case "Low":
      return 1;
      break;
    case "Very Poor":
      return 0;
    break;
  }
}