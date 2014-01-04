part of StockBotClient;

@NgController(
    selector: '[loading]',
    publishAs: 'loader'
)
class Loading {
  bool loaded = false;
  Loading () {

      getRequest("/Session/Get").then((HttpRequest req) { 
        JsonData sess = new JsonData(req.responseText);
        if (sess.getBool("loggedIn")) {
          JsonData data = sess.getJsonDataMap("user");
          if (data != null) {
            User tempU = new User(data.getNum("userID"), data.getString("username"), new DateTime.fromMillisecondsSinceEpoch(data.getNum("creationDate"), isUtc: true), new DateTime.fromMillisecondsSinceEpoch(data.getNum("lastLogin"), isUtc: true),
                data.getBool("active"), data.getBool("isAdmin"), data.getBool("apiAllowed"), data.getString("lastIp"), data.getString("apiKey"), data.getNum("tornID"));
            StockBotModule.user = tempU;
            StockBotModule.loggedIn = true;
            StockBotModule.tryStockUpdate().then((bool complete) {
              loaded = true;
            }).catchError((e) { 
              // TODO: DISPLAY ERROR SCREEN;
            });
          }
          else loaded = true;
        }
        else loaded = true;
      });
    }
}
