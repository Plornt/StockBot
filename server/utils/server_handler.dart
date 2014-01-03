part of StockBot;

class User {
  static Map<String, User> _users = new Map<String, User>();

  User._create(String this.username, String this.password) {
    print("Created $username $password");
    _users[username] = this;
  }
  
  factory User (String username, {String password, int tornID: 0 }) {
    if (_users.containsKey(username)) {
      return _users[username];
    }
    else if (password != null) {
      User user = new User._create(username, password);
      DateTime now = new DateTime.now();
      user.creationDate = now;
      user.lastLogin = now;
      if (tornID != 0) {
        user.tornID = tornID;
      }
    }
    else throw "Password is required to create a new user";
  }
  
  static bool exists (String username) {
    return _users.containsKey(username);
  }
  
  static User get (String username) {
    return _users[username];
  }
  
  static User checkUsernameAndPassword (String username, String password) {
   
    User user = _users.values.firstWhere((User u) { return u.username == username && u.password == password; }, orElse: () { return null; });
    return user;
  }
  
  int userID;
  int activatedById = 0;
  String username = "";
  String password = "";
  DateTime creationDate;
  DateTime lastLogin;
  bool active = false;
  bool isAdmin = false;
  bool apiAllowed = false;
  String lastIp = "None";
  String apiKey = "";
  int tornID = 0;
  
    
  Future<bool> updateDatabase (DatabaseHandler dbh) {
    Completer c = new Completer();
    dbh.prepareExecute("INSERT INTO users (userID, username, password, activatedById, creationDate, lastLogin, active, isAdmin, apiAllowed, lastIp, apiKey)" 
                       " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE username=VALUES(username),  password=VALUES(password), activatedById=VALUES(activatedById), creationDate=VALUES(creationDate),"
                       " lastLogin=VALUES(lastLogin), active=VALUES(active), isAdmin=VALUES(isAdmin), apiAllowed=VALUES(apiAllowed), lastIp=VALUES(lastIp), apiKey=VALUES(apiKey)",
                       [userID, username, password, activatedById, (creationDate == null ? null : creationDate.millisecondsSinceEpoch), (lastLogin == null ? null : lastLogin.millisecondsSinceEpoch), (active ? 1 : 0), (isAdmin ? 1 : 0), (apiAllowed ? 1 : 0), lastIp, apiKey]).then((Results res) { 
                          c.complete(true);    
                       });
    
    return c.future;
  }
  
  
  static Future<bool> init (DatabaseHandler dbh) {
    Completer c = new Completer();
    dbh.query("SELECT userID, username, password, activatedById, creationDate, lastLogin, active, isAdmin, apiAllowed, lastIp, apiKey FROM users").then((Results res) { 
      res.listen((Row user) { 
        User curUser = new User._create(user[1], user[2]);
        curUser.userID = user[0];
        curUser.activatedById = user[3];
        if (user[4] != null) { 
          curUser.creationDate = new DateTime.fromMillisecondsSinceEpoch(user[4]);
        }
        if (user[5] != null) {
          curUser.lastLogin = new DateTime.fromMillisecondsSinceEpoch(user[5]);
        }
        curUser.active = user[6] == 1 ? true : false;
        curUser.isAdmin = user[7] == 1 ? true : false;
        curUser.apiAllowed = user[8] == 1 ? true : false;
        curUser.lastIp = user[9];
        curUser.apiKey = user[10];
      })
      .onDone(() { 
        c.complete(true);        
      });     
      
    });
    return c.future;
  }
}

class Parameters {
  List<String> parameters = new List<String>();
  Parameters([List<String> this.parameters]);
  
  int get length {
    return parameters.length;
  }
  
  String get (int index) {
    if (index < parameters.length && index >= 0) return parameters[index];
    else return "";
  }
  
  num getN (int index) {
    if (index < parameters.length && index >= 0) { 
      return num.parse(parameters[index],  (e) { return 0; });
    }
    else return 0;
  }
}

class PostData {
  Map<String, String> data = new Map<String, String>();
  
  String get (String key) {
    if (data.containsKey(key)) {
      return data[key];
    }
  }
  num getN (String key) {
    if (data.containsKey(key)) { 
      String val = data[key];
      if (val.length > 1000) {
         val = val.substring(0, 1000);
      }
      return num.parse(val,  (e) { print("Error?"); return 0; });
    }
    else return 0;
  }
  PostData.parseFromString(String stringdata) { 
    List<String> splits = stringdata.split("&");
    splits.forEach((String kv) {
      List<String> keyVals = kv.split("=");
      String key = keyVals[0];
      String value = "";
      if (keyVals.length > 1) {
        value = keyVals.getRange(1, keyVals.length).join("=");
      }
      data[key] = value; 
    });
  }
}

class StockServer {
  InternetAddress bindIp;
  int port;
  StockServer (InternetAddress this.bindIp, int this.port) {
    
  }
  
  Future<bool> sendFile (HttpRequest request, String filePath) {
    Completer c = new Completer();
    final File file = new File('../web/$filePath');
    file.exists().then((bool found) {
      if (found) {
        file.openRead()
          .pipe(request.response).then((d) { 
            c.complete(true);
          })
            .catchError((e) { c.complete(false); });
      }
      else { 
        c.complete(false);
      }
      });
    return c.future;
  }
  void _handleRequest (HttpRequest request, PostData data) {
    List<String> path = request.uri.pathSegments;
    print(path);
    bool handled = false;
    if (path.length > 0) {
      if (path[0] != "") {
        if (ServerPage.exists(path[0])) {
          ServerPage page = ServerPage.getPage(path[0], request, data);
          String pageSubHandler = "";
          if (path.length >= 2) pageSubHandler = path[1];
          Parameters params = new Parameters();
          if (path.length >= 3) { 
            params.parameters = path.getRange(2, path.length);
          }
          handled = page.getSubPage(pageSubHandler, params);

          request.response.close();
        } 
        else {
          // Sanitizing the hell out of this path. I dont have time to check how to do this properly.
           String fullPath = pathLib.joinAll(path);
           fullPath = pathLib.normalize(fullPath);
           List<String> splitPath = pathLib.split(fullPath);
           List<String> sanitizedPath = new List<String>();
           splitPath.forEach((String pathSeg) { 
             if (pathSeg != ".." && pathSeg != ".") {
               sanitizedPath.add(pathSeg);
             }
           });
           fullPath = pathLib.joinAll(sanitizedPath);
           if (fullPath.length > 0) {
             sendFile(request, fullPath).then((bool done) { 
               if (!done) {              
                 send408(request);
               }
             });
           }
           else send408(request);
        }
      }
    }
    else {
      sendFile(request, "index.html").then((bool done) { 
        print("Found null");
        if (!done) {
          send408(request);
        }
      });
    }
  }
  
  void StartServer () {
    ServerPage.init();
    HttpServer.bind(bindIp, port).then((server) {
      server.listen((HttpRequest request) {
        String postData = "";
        request.transform(new Utf8Decoder(allowMalformed: true)).listen((String data) { 
          postData += data;
          // TODO: Do some security checks so socket cannot be DDOS'ed via massively long post data sends.
        }, onError: (e) {
          print("ERROR : $e");
        }).onDone(() { 
          _handleRequest(request, new PostData.parseFromString(postData));
        });
      });
    });
  }
  void send408 (HttpRequest req) { 
    req.response.statusCode = HttpStatus.NOT_ACCEPTABLE;
    req.response.write("No suitable page could be found to handle your request");
    req.response.close();
  }
}

abstract class ServerPage { 
  User requestingUser;
  String fileType = ""; 
  bool loggedIn = false;
  
  HttpRequest request;  
  HttpResponse get response {
    return request.response;
  }
  HttpSession get session {
    return request.session;
  }
  PostData postData;
  
  ServerPage.create (this.request, this.postData);
  
  bool getSubPage (String pageSubHandler, Parameters parameters) { 
    return false;
  }
  
  static Map<Symbol, ClassMirror> _SERVER_PAGES = new Map<Symbol, ClassMirror>();
  static void init () {
    if (!initialized) { 
      //  Get our current mirror system
      MirrorSystem ms = currentMirrorSystem();
      // Get the current isolate in the mirror system
      IsolateMirror im = ms.isolate;
      // Get the root library for the isolate
      LibraryMirror lm = im.rootLibrary;
      // Get the current classes in the root library
      Map<Symbol, DeclarationMirror> declorationmirrormap = lm.declarations;
      // Loop through all the classes searching for server pages
      declorationmirrormap.forEach((symbol, declarationMirror) { 
          if (declarationMirror is ClassMirror) {
            // Check the class has a super clas
            if (declarationMirror.superclass != null) {
              ClassMirror superClass = declarationMirror.superclass;
              // Check the name of the super class has the name we require
              if (superClass.simpleName == new Symbol("ServerPage")) {
                _SERVER_PAGES[declarationMirror.simpleName] = declarationMirror;                              
              }
            }
          }
      });
      initialized = true;
    }
  }
  static bool initialized = false;
  static exists (String pageName) { 
    Symbol pageSymbol = new Symbol(pageName);
    return _SERVER_PAGES.containsKey(pageSymbol);
  }
  static ServerPage getPage (String pageName, HttpRequest request, PostData data) { 
    Symbol pageSymbol = new Symbol(pageName);
    if (_SERVER_PAGES.containsKey(pageSymbol)) {
      return _SERVER_PAGES[pageSymbol].newInstance(new Symbol("create"), [request, data]).reflectee;
    }
    return null;
  }
}

class AccountPage extends ServerPage { 
 AccountPage.create (request, postdata):super.create(request, postdata);
 bool getSubPage (String page, Parameters parameters) { 
   if (page == "Login") {
     login(postData.get("username"), postData.get("password"));
   }
   return true;
 }
 
 void login(String username, String password) {
   if (username != "" && password != "") {
     User tUser = User.checkUsernameAndPassword(username, password);
     if (tUser != null) {
       response.write("Logged in : ${tUser.username}");
       
     }
     else response.write("Incorrect username or password. $username $password");
   }
 }
}