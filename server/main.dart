import 'package:logging/logging.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:html5lib/parser.dart' as parser;
import 'package:html5lib/dom.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class Request {
  String url = "";
  Completer c;
  Map<String, String> postData;
  Request (this.url, this.postData, this.c);
}
class TornGetter {
  String username = "";
  String password = "";
  bool selfLogin = true;
  bool loginFailed = false;
  HttpClient client = new HttpClient();
  bool loggedIn = false;  
  bool _attemptingLogin = false;
  List<Request> queued = new List<Request>();
  List<Cookie> cookies = new List<Cookie>();
  TornGetter ({this.username, this.password, this.selfLogin: true, String PHPSESSID: ""}) {
    if (PHPSESSID != "") {
      loggedIn = true;
      cookies.add(new Cookie("PHPSESSID", PHPSESSID));
    }
  }
  Future<String> request (String url, { Map<String, String> postData, needLogin: true}) {
    Completer c = new Completer();
    if (loggedIn || needLogin == false) {
      _doRequest(new Request(url, postData, c));
    }
    else {
      if (!_attemptingLogin) { 
        if (selfLogin == true) {
          _attemptingLogin = true;
           tryLogin(3, 0).then((bool done) {
             if (done) {
                 loginFailed = false;
                 loggedIn = true;
                 _attemptingLogin = false;
                 _doRequest(new Request(url, postData, c));
                 queued.forEach(_doRequest);
                 queued = new List<Request>();
             }
             else {
               loginFailed = true;
               c.completeError("Could not login.");
             }
           });
        }
        else c.completeError("Could not login.");
      }
      else queued.add(new Request(url, postData, c));
    }

    return c.future;
  }
  
  Future<String> _doRequest (Request req) {
    String url = req.url;
    Map<String, String> postData = req.postData;
    Completer c = req.c;
    void requestSent (HttpClientResponse html) {
      String htmlData = "";
      html.transform(new Utf8Decoder(allowMalformed: true)).listen((String data) {
        htmlData += data;
      }).onDone(() {
        if (!htmlData.contains("You are no longer logged in")) {
                 c.complete(htmlData);
        }
        else {
          if (this._attemptingLogin != true) {
            this._attemptingLogin = true;
            tryLogin(3, 0).then((val) { 
              if (val) {
                loginFailed = false;
                loggedIn = true;
                _attemptingLogin = false;
                queued.forEach(_doRequest);
                queued = new List<Request>();
                return this._doRequest(req);
              }
              else c.completeError("Could not login");
            });
          }
          else {
            this.queued.add(req);
          }
        }
      });
    }
    if (postData == null) {
      client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
        request.cookies.addAll(this.cookies);
        return request.close();
      })
      .then((HttpClientResponse response) { 
        requestSent(response);
      });
    }
    else {
      client.postUrl(Uri.parse(url)).then((HttpClientRequest req) { 
        StringBuffer sb = new StringBuffer();
        postData.forEach((k, v) { 
          sb..write(k) 
            ..write("=")
            ..write(v)
            ..write("&");
        });
        req.cookies.addAll(cookies);
        req.contentLength = sb.toString().length;
        req.headers.set("Content-Type", "application/x-www-form-urlencoded");
        req.write(sb);
        return req.close();
      }).then((HttpClientResponse response) { 
        this.cookies = response.cookies;
        requestSent(response);
      });
    }
    return c.future;
  }
  
  Future<bool> tryLogin (int MaxAttempts, int AttemptNumber, [Completer c]) {
    if (c == null) c = new Completer();
    this.login().then((val) { 
      if (val == true) {
        c.complete(true);
      }
      else {
        if (AttemptNumber < MaxAttempts) {
          print("[${AttemptNumber+1}/$MaxAttempts] Could not login. Retrying...");
          tryLogin(MaxAttempts, AttemptNumber + 1, c);
        }
        else c.complete(false);
      }
    });
    return c.future;
  }
  
  Future<bool> login () {
    Completer c = new Completer();
    this.request("http://www.torn.com/authenticate.php", postData: { 
      'player': this.username,
      'password': this.password
    }, needLogin: false).then((String htmlData) {
        if (htmlData.contains("You have logged on")) {
          loggedIn = true;
          c.complete(true);
        }
        else {
          c.complete(false);
        }
    });
    return c.future;
  }
  
}

class QueryQueue {
  List<List<dynamic>> parameters = new List<dynamic>();
  List<Completer> c = new List<Completer>();
  QueryQueue();
  void add (List<dynamic> params, Completer comp) {
     parameters.add(params);
     c.add(comp);
  }
}

class DatabaseHandler {
  ConnectionPool _connectionPool;

  /// Caches the query
  Map<String, Query> _queryCache = new Map<String, Query>();
  Map<String, QueryQueue> _queue = new Map<String, QueryQueue>();

  DatabaseHandler (this._connectionPool);

  /// Executes a query
  Future<Results> query(String sql) {
    return _connectionPool.query(sql);
  }

  /// Prepares an sql statement and returns the Query ready for execution. Prepared statement is cached.
  Future<Query> prepare (String sql) {
    Completer c = new Completer();
    if (!_queryCache.containsKey(sql)) {
      _connectionPool.prepare(sql).then((Query E) {
        _queryCache[sql] = E;
        _processQueue(E, sql);
        c.complete(E);
      }).catchError((e) { c.completeError(e); });
    }
    else {
      print("Using cache");
      c.complete(_queryCache[sql]);
    }
    return c.future;
  }
  void _processQueue (Query q, String sql) {
     if (_queue.containsKey(sql)) {
       int qL = _queue[sql].parameters.length;
       QueryQueue curr = _queue[sql];
       for (int x = 0; x < qL; x++) {
         q.execute(curr.parameters[x]).then((v) => curr.c[x].complete(v)).catchError((e) => curr.c[x].completeError(e));
       }
       _queue.remove(curr);
     }
  }

  /// Prepares a sql statement then executes with the supplied parameters and caches the prepared statement.
  Future<Results> prepareExecute (String sql, List<dynamic> parameters) {
    Completer c = new Completer();
    // We want to check if a query is being prepared already
    // If we do a loop elsewhere and then try to execute, the issue is the prepared
    // query doesnt get prepared before theyre all sent through
    // So we end up essentially having a useless cache
    if (!_queue.containsKey(sql)) {
      _queue[sql] = new QueryQueue ();
      this.prepare(sql).then((Query q) {
        q.execute(parameters).then((E)  => c.complete(E)).catchError((e) => c.completeError(e));
      }).catchError((e) { c.completeError(e); });
    }
    else {
      _queue[sql].add(parameters, c);
    }
    return c.future;
  }

  /// Returns the number of rows a sql statement returns.
  Future<int> getNumRows (sql, parameters) {
    Completer c = new Completer();
    this.prepareExecute(sql, parameters).then((row) {
      row.listen((res) {
        c.complete(res[0]);
      }, onDone: () {
        if (!c.isCompleted) c.complete(0);
      });
    }).catchError((e) { c.completeError(e); });
    return c.future;
  }
}
///html/body/div[4]/table/tbody/tr/td[2]/table/tbody/tr[3]/td/table/tbody/tr/td[2]/table/tbody/tr[1]/td[2]
String stockCostSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(0) > TD:eq(1)";
String acronymSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR > TD:eq(1)";
String nameSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > CENTER:eq(0) > FONT:eq(0) > B:eq(0)";
String infoSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0)";
String directorSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR:eq(2) > TD:eq(1)";
String marketCapSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(2) > TD:eq(1)";
String demandSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(0) > TABLE > TBODY > TR:eq(6) > TD:eq(1)";    
String totalSharesSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(4) > TD:eq(1)";
String sharesForSaleSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD:eq(1) > TABLE > TBODY > TR:eq(6) > TD:eq(1)";
String forecastSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:last-child > TABLE:eq(0) > TBODY:eq(0) > TR > TD > TABLE > TBODY > TR > TD > TABLE > TBODY > TR:eq(4) > TD:eq(1)";

class Stock {
  int id = 0;
  static Map<int, Stock> _STOCKS = new Map<int, Stock>();
  String acronym = "";
  String name = "";
  String info = "";
  String director = "";
  String marketCap = "";
  num totalShares = 0;
  num sharesForSale = 0;
  String demand = "";
  String forecast = "";
  bool errored = false;
  num currentPrice = 0;
  
  
  
  Stock._create (this.id) {
    _STOCKS[id] = this;
  }
  
  factory Stock (int ID) { 
    if (_STOCKS.containsKey(ID)) {
      return _STOCKS[ID];
    }
    else return new Stock._create(ID);
  }
  
  Future<StockData> getTimeRange (DateTime timeFrom, DateTime timeTo) {
    
  }
  
  Future<bool> fetchLatestData (TornGetter tg) {
    Completer c = new Completer();
    
    tg.request("http://www.torn.com/stockexchange.php?step=profile&stock=$id").then((data) { 
      Document parsed = parser.parse(data);
      
      try { 
        this.currentPrice =  num.parse(childQuerySelector(parsed.body, stockCostSelector)[0].innerHtml.replaceAll(",", "").replaceAll(r"$", ""), (e) { return 0; });
        this.acronym = childQuerySelector(parsed.body, acronymSelector)[0].innerHtml;    
        this.name = childQuerySelector(parsed.body, nameSelector)[0].innerHtml;  
        this.info = childQuerySelector(parsed.body, infoSelector)[0].innerHtml;  
        this.director = childQuerySelector(parsed.body, directorSelector)[0].innerHtml;  
        this.marketCap = childQuerySelector(parsed.body, marketCapSelector)[0].innerHtml;  
        this.demand = childQuerySelector(parsed.body, demandSelector)[0].innerHtml;
        this.totalShares = num.parse(childQuerySelector(parsed.body, totalSharesSelector)[0].innerHtml.replaceAll(",", ""), (e) { return 0; });
        this.sharesForSale = num.parse(childQuerySelector(parsed.body, sharesForSaleSelector)[0].innerHtml.replaceAll(",", ""), (e) { return 0; });
        this.forecast = childQuerySelector(parsed.body, forecastSelector)[0].innerHtml;
  
        c.complete(true);
      }
      catch (e) {        
        c.completeError(e);
        this.errored = true;
      }
    }).catchError(c.completeError);
    return c.future;
  }
  
  Future<bool> insertIntoDb () {
    
  }
  
  
  toJson () {
    return { 'id': id, 'currentPrice':currentPrice, 'acronym': this.acronym, 'name': this.name, 'info': this.info, 'director': this.director, 'marketCap': this.marketCap, 'demand': this.demand, 'totalShares': this.totalShares, 'sharesForSale': this.sharesForSale, 'forecast': this.forecast };
  }
}


class StockData {
  int time = 0;
  num CPS = 0.0;
  int sharesAvailable = 0;  
}

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