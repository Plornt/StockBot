part of StockBot;

class StockInfo extends ServerPage { 
  StockInfo.create (request, postdata):super.create(request, postdata);
  bool getSubPage (String page, Parameters parameters) {
    if (session.containsKey("userID")) {
      if (page == "GenericData") {
        if (parameters.length == 1) {
          int stockID = parameters.getN(0).toInt();
          if (Stock._STOCKS.containsKey(stockID)) {
            sendJson(Stock._STOCKS[stockID].toJson());          
            return true;
          } 
        }
        else {
          sendJson(Stock._STOCKS.values.toList());    
         return true;
        }
      }
    }
    else if (page == "PricingData") {
      DateTime dateTo;
      DateTime dateFrom;
      int stockID = 0;
      print("its pricing data");
      if (parameters.length >= 1) {
        stockID = parameters.getN(0).toInt();
        if (parameters.length >= 2) {
          print("Params greater than 2 and 1");
           int date = parameters.getN(1).toInt();
           if (date > 0) {
             print("date is greater than 0");
             dateFrom = new DateTime.fromMillisecondsSinceEpoch(date, isUtc: true);
             if (parameters.length >= 3) {
               int dateT = parameters.getN(2).toInt();
               dateTo = new DateTime.fromMillisecondsSinceEpoch(dateT, isUtc: true);
             }
             else dateTo = new DateTime.now().toUtc();
             
             if (Stock._STOCKS.containsKey(stockID)) {
               Stock reqStock = Stock._STOCKS[stockID];
               print("Getting data for server");
               reqStock.getTimeRange(dbh, dateFrom, dateTo).then((TimedStockData d) { 
                 sendJson(d);    
                 
               }).catchError((E) {
                 this.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
                 this.response.writeln("An internal server error occured1");
                 this.response.close();
               });
               return true;
             }
             
           }
        }
      }
    }
    return false;
  }
  
  
  
  
}