library StockBot;

import 'package:logging/logging.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:html5lib/parser.dart' as parser;
import 'package:html5lib/dom.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

part 'classes/stock.dart';
part 'utils/database_handler.dart';
part 'utils/html_utilities.dart';
part 'utils/torn_getter.dart';

DatabaseHandler dbh = new DatabaseHandler(new ConnectionPool(host: 'localhost', port: 3306, user: 'plornt', password: 'roflman1', db: 'stocks', max: 5));
void main () {
  
  TornGetter tg = new TornGetter(username: "Plorntus", password: "roflman1", selfLogin: false, PHPSESSID: "f2e27838f371222286d9b90a260640b9");
  List<Stock> stocks = new List<Stock>();
  for (int i=0; i<=31; i++) {
    if (i == 24) continue;
    Stock stock = new Stock(i);
    stock.fetchLatestData(tg).then((dat) { 
      stocks.add(stock);
      print("[${stocks.length}/31] Got data from stockID $i");
      if (stocks.length == 31) {
        JsonEncoder encoder = new JsonEncoder();
        print(encoder.convert(stocks));
      }
    });
  }
}