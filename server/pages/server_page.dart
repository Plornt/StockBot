part of StockBot;


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
  void sendJson (dynamic obj) {
    try {
      String json =  JSON.encode(obj);
      print("Sending data");
      response.write(json);
      response.close();
    }
    catch (e) {
      response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      response.write("Internal server error: $e : ");
      response.close();
    
    }
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