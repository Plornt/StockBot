library StockBot;

import 'package:logging/logging.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:html5lib/parser.dart' as parser;
import 'package:html5lib/dom.dart';
import 'package:path/path.dart' as pathLib;
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:mirrors';

part 'classes/stock.dart';
part 'utils/database_handler.dart';
part 'utils/html_utilities.dart';
part 'utils/torn_getter.dart';
part 'utils/server_handler.dart';

DatabaseHandler dbh = new DatabaseHandler(new ConnectionPool(host: 'localhost', port: 3306, user: 'plornt', password: 'roflman1', db: 'stocks', max: 5));
void main () {

  StockServer server = new StockServer(InternetAddress.ANY_IP_V4, 80);
  server.StartServer();
  
  ServerPage.init();
  
  TornGetter tg = new TornGetter(username: "Plorntus", password: "roflman1", selfLogin: false, PHPSESSID: "f2e27838f371222286d9b90a260640b9");
  JsonEncoder encoder = new JsonEncoder();
 // refreshData(tg);
  new Timer.periodic(new Duration(minutes: 5),(A) { 
    refreshData(tg);
  });
  
}

void refreshData (TornGetter tg) {
  User.init(dbh);
  Stock.init(dbh).then((done) { 
    print("Fetching data");
    Stock._STOCKS.forEach((int id, Stock tcsb) {
        tcsb.fetchLatestData(tg).then((done) { 
            tcsb.updateDB(dbh).then((d) { 
              print("Updated DB");
            });
        });
      });
    });
}