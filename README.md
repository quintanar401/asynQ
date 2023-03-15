# Async functions in Q

The library allows you to call functions that may not return immediately. It can be used to create CEP processes, async Gateways and etc. In addition you gain access to function's continuations - like call/cc in scheme - that is you can resume some function many times.

There are severe limitations of course: all async calls must be marked with async keyword in all call chain, the initial function or a continuation must be started via the library functions, you can't use async functions in adverbs or QSQL.
```q
.rdb.processTrade:{[msg]
  someProc msg;
  async .cep.delay 0D00:05; / wait a bit
  async .cep.split[msg;.rdb.processX;1 2 3;::]; / split msg, process, and aggregate
 };
.rdb.processX:{[msg]
  process msg;
  async i:.cep.requestInfoInHDB[msg];
  : process[msg;i];
 };
/ somewhere there is a call
.cep.enqueue[.rdb.processTrade;msg]; / or .as.run1[.rdb.processTrade;msg] - to start the fn right away
```

The library works by splitting all async functions (functions that use async keyword) into blocks - sync blocks and async calls and then executes them in a loop taking care of local variables and maintaining async call stack. The overhead is negligible for real functions. For example `.rdb.processTrade` would be split into (approximately):
```q
{someProc msg},{(asyncFn indicator;.cep.delay;0D00:05)},{(asyncFn indicator;.cep.split;(msg;.rdb.processX;1 2 3;::))},{::}
```

For example how asyn.q can be used to build a cep see cep.q and CEP.md.

## Usage

Async call must occupy one whole statement and this statement must be a statement in the parent expression and so up to top. That is you can use async in if, while, do, $(case), between ";" in a statement list but can't use it in the arguments of a function or as an element of a list/any expression:
```q
if[async ..; ] / ok
$[async ..; async ..; async ..] / all ok
1+$[async ..;..;...] / not ok - $[..] is not a statement
(async ..;..) / not ok - part of an expression, not statement
$[[async ...;1];..;..] / ok, [..] is a list of statements
```
to put it simply if you apply parse to a function the path to any async expression must go only via ";", \`do, \`while, \`if and $(case).

Async expression looks like:
* async expression - a simple call
* async var: expression - the result is saved into var (local or global).
* : async expression - the result is returned.
* async : expression - the same as : async expression.

where expression can be one of (args can be any expressions including assigns):
* fn arg
* fn[arg1;arg2;..]
* @[fn;arg;handler]
* .[fn;(arg1;..);handler]

and fn is one of:
* function name
* function itself - {...}, it can't be parted!
* local variable with the name/function

fn can be parted but only if it is used by name (it is hard to extract it otherwise).

Examples:
```q
async .cron.delay 0D00:03
: async calc[x+1;10]
async v: @[.cep.split;msg;{...}]
```

You can use any function (type 100) with async keyword but only two types are not trivial:
* async functions - functions with async keyword.
* CPS functions (continuation passing style) - these are ordinary functions that have cont as the first argument: {[cont;..] }, where cont is the current continuation.

CPS functions are endpoints that store cont until the return value is ready. For example:
```q
.cron.delay:{[cont;tm] .cron.addJob[... set fn to {.as.resume[x;::]}, arg to cont, time to .z.P+tm...]; :`async}
/ and in an async func
async .cron.delay 0D00:03; / returns after 3 min
```

Allowed return values:
* value - any Q value.
* exception - Q exception as well.
* \`async - terminate the current async call (it can be resumed later via a continuation).
* (\`asyncExc;value) - raise an exception, it can be caught by an async catch block. Set .as.debug to 1b to print the current async stack with all functions and local vars on each exception.

Continuations:
* if you call them from an async/CPS function then you MUST immediately return their value: `: cont val`.
* otherwise call them via `.as.resume[cont;val]`. Resume can be called from an async fn too, it will start a new async loop.

## Exception blocks

You can use the usual Q try block with async:
```q
async @[fn;arg;handler] / and all other variants with assign and return
async .[fn;args;handler]
```
handler shouldn't be async.

To raise an exception use ' or return (\`asyncExc;value) from a function (in async function do this explicitly with :):
```q
async { if[bad; :(`asyncExc;value)]; ..}[];
```

## Adverbs and QSQL

Async funcs do not work with adverbs/QSQL. However for adverbs there are async analogs: .as.each, .as.scan and etc.
```q
async .as.each[{async .cep.delay 0D00:00:10;x+1};enlist 1 2 3];
```

## API

* .as.run[fn;arglst] - run fn using arg list. Starts a new async loop.
* .as.run1[fn;arg] - run unary/nilladic fn using arg. Starts a new async loop.
* .as.resume[cont;arg] - resume a continuation. Starts a new async loop.
* .as.each[fn;arglist] - async analog of '
* .as.over[fn;arglist] - async analog of /
* .as.scan[fn;arglist] - async analog of \\
* .as.prior[fn;arglist] - async analog of ':
* .as.eachr[fn;arglist] - async analog of /:
* .as.eachl[fn;arglist] - async analog of \\:
* .as.show fn - return blocks in which an async fn is splitted.
* .as.debug - set to 1b to print all exceptions in async funcs - stack and local vars.
* .as.err - function used by .as.trap when .as.debug is 1b.
* .as.trap - function that is called for each async exception.

Iterators:
* .as.iCall1[fn;arg] and .as.iCall[fn;args] - call an async iterator function fn with 1 or several args. Returns a list (iter;val). The list should be used with iNext to get the next val.
* .as.iNext[iter;val] - resume an iterator, returns a list of (iter;val) that should be passed to the next iNext call.
* async .as.iRet val - return a value to a caller.

Example:
```q
f1:{f:f2; while[1; f:.as.iCall1[f;1]; if[10=last f; :10]]}; / function that use an iter is not required to be async
f2:{i:0; while[1; async .as.iRet i; i+:1]}; / async iterator

```

## Tail call elimination

As a bonus all async tail calls are eliminated. It means you can replace cycles/adverbs with recursive calls like:
```q
cepLoop:{[a] / infinite recursive loop
  if[count msgs; process 1 msg; : async cepLoop[]];
  async .cron.wait 100;
  async cepLoop[]
 };
```
The call will be eliminated only if a) it is async b) it is the last expression or a return expression c) it is not an exception block.

## .z.s calls

You can use .z.s in async functions but only with async keyword (because .z.s is an async function):
```q
{if[x>10; :x]; async .z.s x+1}
```

## Continuations

These are 100% genuine continuations. For example here is the (in)famous yinyang function that is notoriously hard to understand:
```q
{async yin: {[cont;x] cont}[]; 1 "@"; async yang: {[cont;x] cont}[]; 1 "*"; : yin yang}
```
If you call a continuation from an async fn as above you MUST return its value.

To simplify the continuation capture in async functions there is callcc function (use CPS functions for non-async fns):
```q
async .as.callcc[asyncFn;args];
...
asynFn:{[cont;args...] ...; async ...; : cont val};
```
