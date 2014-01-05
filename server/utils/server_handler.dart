part of StockBot;


class ServerHandler {
  InternetAddress bindIp;
  int port;
  ServerHandler (InternetAddress this.bindIp, int this.port) {
    
  }
  
  Future<bool> sendFile (HttpRequest request, String filePath) {
    Completer c = new Completer();
    final File file = new File('../web/$filePath');
    file.exists().then((bool found) {
      if (found) {
        String ext = pathLib.extension(filePath);
        String mimeType = "text/html";
        switch (ext) {
          case ".html":
            mimeType = "text/html";
            break;
          case ".js":
            mimeType = "text/javascript";
            break;
          case ".css":
            mimeType = "text/css";
            break;
          case ".htm":
            mimeType = "text/html";
            break;
          case ".dart":
            mimeType = "text/dart";
            break;
          default:
            mimeType = "text/$ext";
            break;
        }
        request.response.headers.set("Content-Type", mimeType);
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
            params.parameters = path.getRange(2, path.length).toList();
          }
          handled = page.getSubPage(pageSubHandler, params);
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
    req.response.statusCode = HttpStatus.NOT_IMPLEMENTED;
    req.response.write("No suitable page could be found to handle your request");
    req.response.close();
  }
}
num parseNum (String nums, [num onError(String s)]) {
//  return double.parse(nums,  (String e) {
//    if (onError != null) {
//      return int.parse(nums, onError: onError).toDouble();
//    }
//    else {
//      return int.parse(nums).toDouble();
//    }
//  });
  // Uncomment the above when running on an older dart vm
  
  return num.parse(nums, onError);
}
class Parameters {
  List<String> parameters = new List<String>();
  Parameters([List<String> this.parameters]);
  
  int get length {
    return (parameters != null ? parameters.length : 0);
  }
  
  String get (int index) {
    if (index < parameters.length && index >= 0) return parameters[index];
    else return "";
  }
  
  num getN (int index) {
    if (index < parameters.length && index >= 0) { 
      return parseNum(parameters[index],  (e) { return 0; });
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
      return parseNum(val,  (e) { print("Error?"); return 0; });
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
