part of StockBot;

class Account extends ServerPage { 
 Account.create (request, postdata):super.create(request, postdata);
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
       session["userID"] = tUser.userID;
       sendJson({ 'loggedIn': true, 'username': tUser.username, 'userID': tUser.userID, 'tornID': tUser.tornID, 'isAdmin': tUser.isAdmin, 'creationDate': tUser.creationDate.millisecondsSinceEpoch, 
         'lastLogin': tUser.lastLogin.millisecondsSinceEpoch, 'lastIp': tUser.lastIp, 'apiAllowed': tUser.apiAllowed, 'apiKey': tUser.apiKey });
       
     }
     else sendJson({ 'loggedIn': false, 'error': 'Incorrect username or password supplied'});
   }
 }
}