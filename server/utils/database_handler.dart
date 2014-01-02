part of StockBot;


class QueryQueue {
  List<List<dynamic>> parameters = new List<dynamic>();
  List<Completer> c = new List<Completer>();
  QueryQueue();
  void add (List<dynamic> params, Completer comp) {
     parameters.add(params);
     c.add(comp);
  }
}

class DatabaseHandler {
  ConnectionPool _connectionPool;

  /// Caches the query
  Map<String, Query> _queryCache = new Map<String, Query>();
  Map<String, QueryQueue> _queue = new Map<String, QueryQueue>();

  DatabaseHandler (this._connectionPool);

  /// Executes a query
  Future<Results> query(String sql) {
    return _connectionPool.query(sql);
  }

  /// Prepares an sql statement and returns the Query ready for execution. Prepared statement is cached.
  Future<Query> prepare (String sql) {
    Completer c = new Completer();
    if (!_queryCache.containsKey(sql)) {
      _connectionPool.prepare(sql).then((Query E) {
        _queryCache[sql] = E;
        _processQueue(E, sql);
        c.complete(E);
      }).catchError((e) { c.completeError(e); });
    }
    else {
      print("Using cache");
      c.complete(_queryCache[sql]);
    }
    return c.future;
  }
  void _processQueue (Query q, String sql) {
     if (_queue.containsKey(sql)) {
       int qL = _queue[sql].parameters.length;
       QueryQueue curr = _queue[sql];
       for (int x = 0; x < qL; x++) {
         q.execute(curr.parameters[x]).then((v) => curr.c[x].complete(v)).catchError((e) => curr.c[x].completeError(e));
       }
       _queue.remove(curr);
     }
  }

  /// Prepares a sql statement then executes with the supplied parameters and caches the prepared statement.
  Future<Results> prepareExecute (String sql, List<dynamic> parameters) {
    Completer c = new Completer();
    // We want to check if a query is being prepared already
    // If we do a loop elsewhere and then try to execute, the issue is the prepared
    // query doesnt get prepared before theyre all sent through
    // So we end up essentially having a useless cache
    if (!_queue.containsKey(sql)) {
      _queue[sql] = new QueryQueue ();
      this.prepare(sql).then((Query q) {
        q.execute(parameters).then((E)  => c.complete(E)).catchError((e) => c.completeError(e));
      }).catchError((e) { c.completeError(e); });
    }
    else {
      _queue[sql].add(parameters, c);
    }
    return c.future;
  }

  /// Returns the number of rows a sql statement returns.
  Future<int> getNumRows (sql, parameters) {
    Completer c = new Completer();
    this.prepareExecute(sql, parameters).then((row) {
      row.listen((res) {
        c.complete(res[0]);
      }, onDone: () {
        if (!c.isCompleted) c.complete(0);
      });
    }).catchError((e) { c.completeError(e); });
    return c.future;
  }
}