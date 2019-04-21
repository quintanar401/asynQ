### Async CEP

It is based on asyn.q library. Requires a cron and persistent messages (simple implementation provided).

CEP processes messages and provides functions to control async work flow. The messages are automatically garbage collected.

### Messages

This are persistent messages used by CEP. They are stored in .msgs namespace. You don't have to delete them explicitly they are automatically garbage collected.

## .msg.makeMsg

Make a new message. Additional fields can be provided. Already available fields include \`msgName, \`time and \`status.

```
m:.msg.makeMsg ();
m:.msg.makeMsg `body`header!(tbl;`something);
```

## Access functions

* .msg.get[m] - get the underlying dictionary.
* .msg.getf[m;\`field] - get one field.
* .msg.getfOpt[m;\`field;val] - get one field, return val if it doesn't exist.
* .msg.name - get msgName field.
* .msg.set[m;val] - set \`body field to val.
* .msg.setf[m;\`field;val] - set field to val.
* .msg.copy[m] - copy m into a new message (system fields are not copied).
* .msg.str[m] - return m as a string (.Q.s1 is applied to values).
* .msg.isMsg[m] - check if m is a message.

## Messages

CEP messages have 4 statuses - ok, done, exc, cancelled. When a message is created via .msg.makeMsg it has ok status. To change it status use this functions:

* async .cep.finish msg - set done status
* .cep.cancel msg - cancel it
* .cep.raise[msg;exc] - raise an async exception

The change of status doesn't mean much unless it is a child message. In this case a continuation (return to the parent) will be added to the main cep loop.

CEP does its best to capture orphan exceptions and redirect them to the parent - for every (fn;arg) pair added to the loop it checks if arg is a message and automatically calls raise for any unaccounted exception. All CEP functions with children messages use this protocol thus it is safe to throw exceptions as is:
```
async .cep.split[msg;`fn;1 2 3;::];
...
/ in fn or its subcall
process msg
'"exception"; / it is ok
: (`asyncExc;val); / it is ok
```

### Functions


## .cep.yield

Return control to the main cep loop, put the current function (or rather its continuation) at the end of the main cep queue. It can be used to break a lengthy function into blocks.

```
async .cep.yield[];
```

## .cep.delay

Wait for some time. Time can be timestamp, time/timespan or a function that returns such value.

```
async .cep.delay 0D00:01;
async .cep.delay {00:00:10.0};
```

## .cep.wait

Wait until the predicate is true using time interval.

Params:
* pred - predicate, returns 0b or 1b.
* delay - time interval for .cep.delay

```
async .cep.wait[{count queue};0D00:00:30];
```

## .cep.finish

Explicitly finish a message. It will be finished eventually but it may take a lot of time. To avoid this delay call this function. Note that the parent message will not be processed until all children are finished.

```
async .cep.finish msg; / it will not return if msg is a child. .cep.fork[.cep.finish;msg] can be used to avoid this
```

## .cep.enqueue/.cep.enqueue0

Add (function;param) pair to the main cep loop. enqueue0 requires that param is a message. enqueue will not return if you call it with `async` keyword. enqueue0 will return (a value or async exception) when the provided message is complete.

```
async .cep.enqueue[fn;arg]; / add fn[arg] to the loop, do not return
.cep.enqueue[fn;arg]; / add fn[arg] to the loop
async .cep.enqueue0[fn;msg]; / add fn[msg] to the loop, wait until it is complete
```

## .cep.cancel

Cancel a message.

```
.cep.cancel msg;
```

## .cep.fork

Clones a message, executes it via a function. The result is ignored, calculations proceed in the main function without a delay. It is not an async function and it doesn't require `async` keyword.

Params:
* fn - async function.
* msg - message

```
.cep.fork[.log.msg;msg];
```

## .cep.enrich

Execute an async function with a copy of a message and aggregate the result. It waits until the new message is complete. If the new message fails an async exception with it will be raised. If the main message status changes from ok 'parent: wrong state' exception will be raised.

Params:
* fn - async function.
* msg - message
* agg - aggregation function ({[msg;newMsg] ...}). if agg is (::) then .cep.agg1 (substitute body) will be used.

```
async .cep.enrich[.db.getQuotes;msg;{.msg.set[x] aj[`sym`time;.msg.getf[x;`body];.msg.getf[y;`body]]}];
```

## .cep.split

Generalization of enrich. Split msg into several messages and send them via several functions. Once they are complete, aggregate the result. If any new message fails an async exception with it will be raised, all other children canceled. If the main message status changes from ok 'parent: wrong state' exception will be raised.

The number of messages if controlled by split parameter. fn parameter can have any number of functions.

Params:
* msg - message
* fn - async functions (1 or more).
* split - list of body fields for the new meesages.
* agg - aggregation function ({[msg;newMsgs] ...}). if agg is (::) then .cep.agg (substitute body with raze result) will be used.

```
async .cep.split[msg;.some.fn;.msg.getf[msg`body];::]; / split body(list) into elements and process uniformly using .some.fn
async .cep.split[msg;`fn1`fn2`fn3;3#enlist .msg.getf[msg;`body];{.msg.set[x] raze .msg.getf[;`body] each y}]; / another case - enrich msg using 3 different funcs
```

## Iterators

* .cep.iGet[fn] - initialize an iterator with an async function.
* .cep.iCall[iter;args] or .cep.iCall1[iter;arg] - call an iterator for the first time.
* .cep.iNext[iter;val] - call an iterator again.
* async .cep.iRet[val] - return a value from an iterator, calcs can be resumed from this place.

If you return a value without iRet or throw an exception then the iterator will be done, any subsequent call will produce empty exception.

Example:
```
it:.cep.iGet .cep.myLoop;
v:.cep.iCall[it;100]; / number of iterations
while[1; v:.[.cep.iNext;(it;v-1);::]; if[10=type v; :0]];
...
.cep.myLoop:{[n]
  async .cep.iRet n; / init phase
  while[n; async n:.cep.IRet n];
 };
```