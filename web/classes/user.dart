part of StockBotClient;

class User {
  int userID;
  String username = "";
  DateTime creationDate;
  DateTime lastLogin;
  bool active = false;
  bool isAdmin = false;
  bool apiAllowed = false;
  String lastIp = "None";
  String apiKey = "";
  int tornID = 0;
  
  User (this.userID, this.username, this.creationDate, this.lastLogin, this.active, this.isAdmin, this.apiAllowed, this.lastIp, this.apiKey, this.tornID);
  
}