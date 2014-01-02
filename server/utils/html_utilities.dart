part of StockBot;

RegExp EQ_SELECTOR = new RegExp(r"eq\(([0-9]*)\)");
List<Element> childQuerySelector (Element doc, String selector) {
  List<String> splitSelector = selector.split(">");
  List<Element> potentialElements = new List<Element>()..add(doc);
  for (int x = 0; x < splitSelector.length; x++) {  
    List<String> subSelector = splitSelector[x].trim().split(":");
    int eq = 0;
    bool eqSelector = false;
    bool lastChild = false;
    bool firstChild = false;
    if (subSelector.length == 2) {
      Match match = EQ_SELECTOR.firstMatch(subSelector[1]);
      if (match != null) {
        eqSelector = true;
        eq = int.parse(match.group(1));
      }
      else if (subSelector[1].toLowerCase() == "last-child") {
        lastChild = true;
      }
      else if (subSelector[1].toLowerCase() == "first-child") {
        firstChild = true;
      }
      else throw "Only eq is implemented at the moment";
    }
    List<Element> tempElems = new List<Element>();
    potentialElements.forEach((doc) {
      int elemNum = 0;
      Element potentialElem;
      for (int i = 0; i<doc.children.length; i++) {
        Element child = doc.children[i];
        if (child.tagName == subSelector[0].toLowerCase() || "#${child.id}"== subSelector[0]) {
          if (eqSelector == true) { 
            if (elemNum == eq) {
              tempElems.add(child);
            }
            elemNum++;
          }
          else if (lastChild) {
            potentialElem = child;
          }
          else if (firstChild) { 
            tempElems.add(child);
            break;
          }
          else {
            tempElems.add(child);
          }
        }
      }
      if (lastChild) tempElems.add(potentialElem);
      
    });
    potentialElements = tempElems;
    if (potentialElements.length == 0) {
      return potentialElements;
    }
  }
  return potentialElements;
}
