part of StockBotClient;

@NgComponent(
    selector: 'chartview',
    publishAs: 'chart',
    templateUrl: '/views/chart-view-component.html',
    map: const {
      'date-from': '@dateFrom',
      'date-to': '@dateTo',
      'stock-id': '@stockId'
    }
)
class ChartView {
  DateTime _dateFrom;
  DateTime _dateTo;
  int _stockId;
  Element element;
  Scope s;
  String plotType = "";
  ChartView (Scope this.s, Element el) { 
    JsObject jQProxy = context[r"$"];
    List stockPrice = new List();
    List sharesForSale = new List();
    // Using a timer as was getting issues with DOM not being loaded
    // Will fix when I figure out how to wait for load using angular
    /// TODO: FIX
    
    new Timer (new Duration(seconds: 1), () { 
      if (Stock.exists(_stockId)) {
        Stock s = Stock.get(_stockId);
        s.getTransactions(new DateTime.now().subtract(new Duration(days: 7)), new DateTime.now());
      }
      DivElement plotContainer = new DivElement();
      plotContainer.style.width = "100%";
      plotContainer.style.height = "100%";
      plotContainer.id = "stockchart$_stockId";
      Element chartBox = el.querySelector("section");
      chartBox.append(plotContainer);
      
      jQProxy.callMethod("plot", [ "#stockchart$_stockId", 
                                   new JsObject.jsify([
                                     { 'data': stockPrice, 'label': "Stock Price" },
                                     { 'data': sharesForSale, 'label': "Shares for Sale", 'yaxis': 2 }
                                   ]),
                                   new JsObject.jsify({
                                     'xaxes': [ { 'mode': "time" } ],
                                     'yaxes': [ { 'min': 0 }, {
                                       'alignTicksWithAxis': 1,
                                       'position': "right"
                                     } ],
                                     'legend': { 'position': "sw" }
                                   })
                                  ]);
    });
  }
  set dateFrom (String mSe) {
    if (mSe != null) {
      _dateFrom = new DateTime.fromMillisecondsSinceEpoch(int.parse(mSe, onError: (s) { return 0; }));
      updateChart();
    }
  }
  
  set dateTo (String mSe) {
    if (mSe != null) {
      _dateTo = new DateTime.fromMillisecondsSinceEpoch(int.parse(mSe, onError: (s) { return 0; }));
      updateChart();
    }
  }
  
  set stockId (String id) {
    if (id != null) {
      _stockId = int.parse(id, onError: (s) { return 0; });
    }
  }
  
  String get stockId => _stockId.toString();
  String get dateTo => _dateTo.millisecondsSinceEpoch.toString();
  String get dateFrom => _dateFrom.millisecondsSinceEpoch.toString();
  
  void updateChart () {
    
  }
  
}