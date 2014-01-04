part of StockBot;

class User {
  static Map<String, User> _users = new Map<String, User>();

  User._create(String this.username, String this.password) {
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
  
  static User getById (int userID) {
    User user = _users.values.firstWhere((User u) { return u.userID == userID; }, orElse: () { return null; });
    return user;
  }
  
  static User checkUsernameAndPassword (String username, String password) {
    User user = _users.values.firstWhere((User u) { return u.username.toLowerCase() == username.toLowerCase() && u.password == password && u.active; }, orElse: () { return null; });
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
    dbh.query("SELECT userID, username, password, activatedById, creationDate, lastLogin, active, isAdmin, apiAllowed, lastIp, apiKey, tornID FROM users").then((Results res) { 
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
        curUser.tornID = user[11];
      })
      .onDone(() { 
        c.complete(true);        
      });     
      
    });
    return c.future;
  }
}