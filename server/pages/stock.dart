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
        }
      }
    }
    return false;
  }
  
  
}