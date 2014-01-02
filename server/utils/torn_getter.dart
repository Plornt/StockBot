part of StockBot;


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
    print("Getting: $url");
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
        request.headers.set("User-Agent", "Toms Chrome Extension. Please contact Tom[1799359] in-game if this extension is causing issues.");
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
        req.headers.set("User-Agent", "Toms Chrome Extension. Please contact Tom[1799359] in-game if this extension is causing issues.");
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