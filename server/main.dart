import 'package:logging/logging.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:html5lib/parser.dart' as parse;
import 'dart:async';

class Stock {
  
  int id = 0;
  
  
  Future<StockData> getTimeRange (DateTime timeFrom, timeTo) {
    
  }
}
class StockData {
  int time = 0;
  num CPS = 0.0;
  int sharesAvailable = 0;  
}
void main () {
 
}