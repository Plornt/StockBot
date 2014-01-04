part of StockBot;

class Session extends ServerPage { 
  Session.create (request, postdata):super.create(request, postdata);
  bool getSubPage (String page, Parameters parameters) { 
    getSessionData();
    return true;
  }
  
  void getSessionData() {
    Map<String, dynamic> sess = new Map<String, dynamic>();
    if (session.containsKey("userID")) {
       User tUser = User.getById(session["userID"]);
       if (tUser != null) {
         sess["loggedIn"] = true;
         sess["user"] = { 'loggedIn': true, 'username': tUser.username, 'userID': tUser.userID, 'tornID': tUser.tornID, 'isAdmin': tUser.isAdmin, 'creationDate': tUser.creationDate.millisecondsSinceEpoch, 
                          'lastLogin': tUser.lastLogin.millisecondsSinceEpoch, 'lastIp': tUser.lastIp, 'apiAllowed': tUser.apiAllowed, 'apiKey': tUser.apiKey };
       }
    }
    else {
      sess["loggedIn"] = false;
    }
    sendJson(sess);
  }
}