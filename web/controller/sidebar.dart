part of StockBotClient;

@NgController(
    selector: 'sidebar',
    publishAs: 'sidebar'
)
class Sidebar {
  bool get loggedIn {
    return StockBotModule.loggedIn;
  }
  List<SidebarLink> links = new List<SidebarLink>();
  SidebarLink activeLink;
  User get user {
    return StockBotModule.user;
  }
  Sidebar (RouteProvider router) {
    links.add(new SidebarLink("Overview", this, "overview"));
    links.add(new SidebarLink("Detailed View", this, "detailed/0"));
  }
}

class SidebarLink {
  String linkName = "";
  Sidebar parent;
  String hash;
  SidebarLink (this.linkName, this.parent, String this.hash);
  //overview
  void onClick () {
    this.parent.activeLink = this;
  }
}