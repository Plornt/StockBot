part of StockBotClient;

////ViewRecipeComponent(RouteProvider routeProvider) {
//_recipeId = routeProvider.parameters['recipeId'];
//}

@NgController(
    selector: '[detailed-overview]',
    publishAs: 'stockview'
)
class DetailedView {
  int stockId = 0;
  bool loaded = true;
  DateTime dateFrom;
  DateTime dateTo;
  Timer updateTimer;
  Stock stock;
  DateTime lastPriceUpdate;
  get allStocks => Stock.stocks;
  DetailedView (RouteProvider routeProvider, Scope s) {
    if (StockBotModule.checkLogin()) {
      String val = routeProvider.parameters['stockID'];
      stockId = int.parse(val == null ? "" : val, onError: (e) { return 0; });
      refresh();
      updateTimer = new Timer.periodic(new Duration(seconds: 30), (Timer t) { 
          refresh();
      });
      s.$on(r"$destroy", () { 
        if (updateTimer != null) updateTimer.cancel();
      });
      
    }
  }
  
  
  void refresh () {
    Stock.fetchStockData(stockId).then((Stock thisS) { 
      loaded = true;
      stock = thisS;
    });
  }
  
}
