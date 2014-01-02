import 'package:logging/logging.dart';
import 'package:sqljocky/sqljocky.dart';
import 'package:html5lib/parser.dart' as parse;
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
      print("Req done");
      html.transform(new Utf8Decoder()).listen((String data) {
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
        requestSent(response);
      });
    }
    return c.future;
  }
  
  Future<bool> tryLogin (int MaxAttempts, int AttemptNumber, [Completer c]) {
    if (c == null) c = new Completer();
    this.login().then((val) { 
      print("Trying login");
      if (val == true) {
        c.complete(true);
      }
      else {
        if (AttemptNumber < MaxAttempts) {
          tryLogin(MaxAttempts, AttemptNumber + 1, c);
        }
        else c.complete(false);
      }
    });
    return c.future;
  }
  
  Future<bool> login () {
    Completer c = new Completer();
    print("Trying login");
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
  Map<int, Stock> _STOCKS = new Map<int, Stock>();
  
  Stock._create (int ID);
  
  factory Stock (int ID) { 
    if (_STOCKS.containsKey(ID)) {
      return _STOCKS[ID];
    }
    else return new Stock._create(ID);
  }
  
  Future<StockData> getTimeRange (DateTime timeFrom, timeTo) {
    
  }
  
  Future<bool> fetchLatestData (DateTime lastUpdate) {
    
  }
}


class StockData {
  int time = 0;
  num CPS = 0.0;
  int sharesAvailable = 0;  
}
void main () {
  print("Getting");
  TornGetter tg = new TornGetter(username: "Plorntus", password: "roflman1");
  tg.request("http://www.torn.com/city.php").then((data) { 
    print(data); print("Getting");
  }).catchError((err) { 
    print(err);
  });
}