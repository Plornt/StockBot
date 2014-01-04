library StockBotClient;
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:convert';

part 'classes/user.dart';
part 'classes/stock.dart';
part 'controller/loading.dart';
part 'controller/sidebar.dart';
part 'controller/login.dart';
part 'controller/overview.dart';

class StockBotModule extends Module {
  static User user;
  static bool loggedIn = false;
  static bool loadedStocks = false;
  static List<Stock> stocks = new List<Stock>();
  
  StockBotModule() {
    factory(NgRoutingUsePushState,
        (_) => new NgRoutingUsePushState.value(false));
    type(RouteInitializer, implementedBy: StockBotRouteInitializer);
    type(Sidebar);
    type(Loading);
    type(Login);
    type(StockOverview);
    type(PaddedFilter);
    type(CommaSeparateFilter);
  }
}

class StockBotRouteInitializer implements RouteInitializer {
  init(Router router, ViewFactory view) {
    router.root
      ..addRoute(
          name: 'overview',
          path: '/overview',
          enter: view('/views/overview.html')
      )
      ..addRoute(
          defaultRoute: true,
          name: '404',
          path: '/',
          enter: view('/views/404.html')
      )
      ..addRoute(
          name: 'index',
          path: '',
          enter: view('/views/index.html')
      );
    //
  }
}
main() {
  ngBootstrap(module: new StockBotModule());
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord r) { print(r.message); });

}

// From dartdocs
String encodeMap(Map data) {
  if (data != null) { 
    List<String> kVs = new List<String>();
    
    data.forEach((String key, dynamic val) { 
      kVs.add("${Uri.encodeComponent(key)}=${Uri.encodeComponent(val.toString())}");
    });
    return kVs.join('&');
  }
}

class JsonData {
  dynamic jsonObj;
  JsonData (String data) { 
    try { 
      jsonObj = JSON.decode(data);
    }
    catch (e) {
     // TODO: proper error handling
      // Do nothing :D!
    }
  }
  
  JsonData.fromMap (Map this.jsonObj);
  
  dynamic get (String key) {
    if (jsonObj is Map) {
      if (jsonObj.containsKey(key)) {
        return jsonObj[key];
      }
    }
    return null;
  }
  
  JsonData getJsonDataMap (String key) {
    dynamic m = get(key);
    if (m is Map) {
      return new JsonData.fromMap(m);
    }
    return null;
  }
  String getString (String key) {
    dynamic val = get(key);
    if (val is String) {
      return val;
    }
    return "";
  }
  bool getBool (String key) {
    dynamic val = get(key);
    if (val is bool) {
      return val;
    }
    return false;
  }
  
  num getNum (String key) {
    dynamic val = get(key);
    if (val is num) {
      return val;
    }
    return 0;
  }
}

Future<HttpRequest> getRequest (String url) {
  Completer c = new Completer();
  HttpRequest httpRequest = new HttpRequest();
  httpRequest.open('GET', url);
  httpRequest.onLoadEnd.listen((ProgressEvent data) {
    if (httpRequest.status == 200) {
      c.complete(httpRequest);
    }
    else {
      c.completeError({ 'status': httpRequest.status, 'statusText': httpRequest.statusText });
    }
  });
  httpRequest.send();
  return c.future;
}

Future<HttpRequest> postRequest (String url, Map data) {
  Completer c = new Completer();
  String encodedData = encodeMap(data);

  HttpRequest httpRequest = new HttpRequest();
  httpRequest.open('POST', url);
  httpRequest.setRequestHeader('Content-type', 
                               'application/x-www-form-urlencoded');
  httpRequest.onLoadEnd.listen((ProgressEvent data) {
    if (httpRequest.status == 200) {
      c.complete(httpRequest);
    }
    else {
      c.completeError({ 'status': httpRequest.status, 'statusText': httpRequest.statusText });
    }
  });
  httpRequest.send(encodedData);
  return c.future;
}