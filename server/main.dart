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

RegExp EQ_SELECTOR = new RegExp(r"eq\(([0-9]*)\)");
List<Element> childQuerySelector (Element doc, String selector) {
  List<String> splitSelector = selector.split(">");
  List<Element> potentialElements = new List<Element>()..add(doc);
  for (int x = 0; x < splitSelector.length; x++) {  
    List<String> subSelector = splitSelector[x].trim().split(":");
    int eq = 0;
    bool eqSelector = false;
    bool lastChild = false;
    bool firstChild = false;
    if (subSelector.length == 2) {
      Match match = EQ_SELECTOR.firstMatch(subSelector[1]);
      if (match != null) {
        eqSelector = true;
        eq = int.parse(match.group(1));
      }
      else if (subSelector[1].toLowerCase() == "last-child") {
        lastChild = true;
      }
      else if (subSelector[1].toLowerCase() == "first-child") {
        firstChild = true;
      }
      else throw "Only eq is implemented at the moment";
    }
    List<Element> tempElems = new List<Element>();
    potentialElements.forEach((doc) {
      int elemNum = 0;
      Element potentialElem;
      for (int i = 0; i<doc.children.length; i++) {
        Element child = doc.children[i];
        if (child.tagName == subSelector[0].toLowerCase() || "#${child.id}"== subSelector[0]) {
          if (eqSelector == true) { 
            if (elemNum == eq) {
              tempElems.add(child);
            }
            elemNum++;
          }
          else if (lastChild) {
            potentialElem = child;
          }
          else if (firstChild) { 
            tempElems.add(child);
            break;
          }
          else {
            tempElems.add(child);
          }
        }
      }
      if (lastChild) tempElems.add(potentialElem);
      
    });
    potentialElements = tempElems;
    if (potentialElements.length == 0) {
      return potentialElements;
    }
  }
  return potentialElements;
}

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