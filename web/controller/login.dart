part of StockBotClient;

@NgController(
    selector: '[login]',
    publishAs: 'login'
)
class Login {
  String username = "";
  String password = "";
  bool get error {
    return errors.length > 0 ? true : false;
  }
  List<String> errors = new List<String>();
  
  static String USERNAME_EMPTY = "Username field is blank.";
  static String PASSWORD_EMPTY = "Password field is blank.";
  
  void done() {
    bool req = true;
    if (this.username == "") {
      req = false;
      addError(USERNAME_EMPTY);
    }
    if (this.password == "") {
      req = false;
      addError(PASSWORD_EMPTY);
    }
    print("TEST $username");
    if (req) {
      errors = new List<String>();
      print("TEST $username");
      postRequest("/Account/Login", { 'username': username, 'password': password }).then((HttpRequest response) { 
        JsonData data = new JsonData(response.responseText);
        if (data.getBool("loggedIn")) {
          // User (this.userID, this.username, this.creationDate, this.lastLogin, this.active, this.isAdmin, this.apiAllowed, this.lastIp, this.apiKey, this.tornID);
          
            User tempU = new User(data.getNum("userID"), data.getString("username"), new DateTime.fromMillisecondsSinceEpoch(data.getNum("creationDate"), isUtc: true), new DateTime.fromMillisecondsSinceEpoch(data.getNum("lastLogin"), isUtc: true),
                data.getBool("active"), data.getBool("isAdmin"), data.getBool("apiAllowed"), data.getString("lastIp"), data.getString("apiKey"), data.getNum("tornID"));
            StockBotModule.user = tempU;
            StockBotModule.loggedIn = true;
            window.location.hash = "/overview";
        }
        else addError(data.getString("error"));
      });
    }
    
  }
  
  void change (String field) { 
    if (field == "username") {
      if (this.username != "") {
        removeError(USERNAME_EMPTY);
      }
    }
    else if (field == "password") {
      if (this.password != "") {
        removeError(PASSWORD_EMPTY);
      }
    }
  }
  
  void removeError (String error) {
    if (errors.contains(error)) errors.remove(error);
  }
  
  void addError (String error) {
    if (!errors.contains(error)) {
      errors.add(error);
    }
  }
}