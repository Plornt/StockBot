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
  bool updatedStockPrice = false;
  DateTime lastUpdate;
  num get change { 
    return this.currentPrice - this.prevPrice;
  }
  Stock (this.id);
}