import 'package:logging/logging.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:html5lib/parser.dart' as parser;
import 'package:html5lib/dom.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';


class TornGetter {
  String username = "";
  String password = "";
  bool selfLogin = true;
  bool loginFailed = false;
  HttpClient client = new HttpClient();
  bool loggedIn = false;  
  List<Cookie> cookies = new List<Cookie>();
  TornGetter ({this.username, this.password, this.selfLogin: true, PHPSESSID: ""}) {
    if (PHPSESSID != "") {
      loggedIn = true;
      cookies.add(PHPSESSID);
    }
  }
  
  Future<String> request (String url, { Map<String, String> postData, needLogin: true}) {
    if (loggedIn || needLogin == false) {
      return _doRequest(url, postData: postData);
    }
    else {
      Completer c = new Completer();
      if (selfLogin == true) {
         tryLogin(3, 0).then((bool done) {
           if (done) {
               _doRequest(url, postData: postData).then((val) { 
                c.complete(val);
              });
           }
           else {
             loginFailed = true;
             c.completeError("Could not login.");
           }
         });

      }
      else c.completeError("Could not login.");
      return c.future;
    }
  }
  
  Future<String> _doRequest (String url, { Map<String, String> postData }) {
    Completer c = new Completer();
    void requestSent (HttpClientResponse html) {
      String htmlData = "";
      print("got data");
      html.transform(new Utf8Decoder(allowMalformed: true)).listen((String data) {
        htmlData += data;
      }).onDone(() {
        if (!htmlData.contains("You are no longer logged in")) {
                 c.complete(htmlData);
        }
        else {
          tryLogin(3, 0).then((val) { 
            if (val) {
              return this._doRequest(url, postData: postData);
            }
            else c.completeError("Could not login");
          });
        }
      });
    }
    if (postData == null) {
      client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
        request.cookies.addAll(cookies);
        return request.close();
      })
      .then((HttpClientResponse response) { 
        this.cookies = response.cookies;
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
    this._doRequest("http://www.torn.com/authenticate.php", postData: { 
      'player': this.username,
      'password': this.password
    }).then((String htmlData) {
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
  
  Stock._create (this.id) {
    _STOCKS[id] = this;
  }
  
  factory Stock (int ID) { 
    if (_STOCKS.containsKey(ID)) {
      return _STOCKS[ID];
    }
    else return new Stock._create(ID);
  }
  
  Future<StockData> getTimeRange (DateTime timeFrom, timeTo) {
    
  }
  
  Future<bool> fetchLatestData (TornGetter tg, DateTime lastUpdate) {
    Completer c = new Completer();
    tg.request("http://www.torn.com/stockexchange.php?step=profile&stock=$id").then((data) { 
      String selector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(4) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD > TABLE";
      Document parsed = parser.parse(data);
      List<Element> pricesTables = childQuerySelector(parsed.body ,selector);
      print(parsed.body.innerHtml);
      try { 
        // Acronym
        String acronymSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1)";
        this.acronym = childQuerySelector(parsed.body, acronymSelector)[0].innerHtml;    
        
        // Name
        String nameSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > CENTER:eq(0) > FONT:eq(0) > B:eq(0)";
        this.name = childQuerySelector(parsed.body, nameSelector)[0].innerHtml;  
        
        // Info
        String infoSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(1) > TD:eq(0) > CENTER:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0)";
        this.info = childQuerySelector(parsed.body, infoSelector)[0].innerHtml;  
        
        // Director
        String directorSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(1)";
        this.director = childQuerySelector(parsed.body, directorSelector)[0].innerHtml;  
        
        // M Cap
        String marketCapSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(1)";
        this.marketCap = childQuerySelector(parsed.body, marketCapSelector)[0].innerHtml;  
        
        // Total S
        String totalSharesSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(4) > TD:eq(1)";
        this.totalShares = num.parse(childQuerySelector(parsed.body, totalSharesSelector)[0].innerHtml.replaceAll(",", ""));
        
        // S For S
        String sharesForSaleSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(6) > TD:eq(1)";
        this.sharesForSale = num.parse(childQuerySelector(parsed.body, sharesForSaleSelector)[0].innerHtml.replaceAll(",", ""));
        // Demand
        String demandSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(4) > TD:eq(1)";    
        this.demand = childQuerySelector(parsed.body, demandSelector)[0].innerHtml;
        
        // Forecast 
        String forecastSelector = "DIV:eq(3) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(1) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(2) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(0) > TD:eq(0) > TABLE:eq(0) > TBODY:eq(0) > TR:eq(4) > TD:eq(1)";
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
    int eq;
    if (subSelector.length == 2) {
      Match match = EQ_SELECTOR.firstMatch(subSelector[1]);
      if (match != null) {
        eq = int.parse(match.group(1));
      }
      else throw "Only eq is implemented at the moment";
    }
    List<Element> tempElems = new List<Element>();
    potentialElements.forEach((doc) {
      int elemNum = 0;
      doc.children.forEach((Element child)  { 
        if (child.tagName == subSelector[0].toLowerCase() || "#${child.id}"== subSelector[0]) {
          if (eq == null) { 
            tempElems.add(child);
          }
          else {
            if (elemNum == eq) {
              tempElems.add(child);
            }
            elemNum++;
          }
        }
      });
    });
    potentialElements = tempElems;
    if (potentialElements.length == 0) {
      return potentialElements;
    }
  }
  return potentialElements;
}

void main () {
  print("Getting");
  TornGetter tg = new TornGetter(username: "Plorntus", password: "roflman1");
  Stock tcsb = new Stock(1);
  tcsb.fetchLatestData(tg, new DateTime.now()).then((dat) { 
    print(tcsb.demand);
  });
}