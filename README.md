# Async functions in Q

The library allows you to call functions that may not return immediately. It can be used to create CEP processes, async Gateways and etc. In addition you gain access to function's continuations - like call/cc in scheme - that is you can resume some function many times.

There are severe limitations of course: all async calls must be marked with async keyword in all call chain, the initial function or a continuation must be started via the library functions, you can't use async functions in adverbs or QSQL.

The library works by splitting all async functions (functions that use async keyword) into blocks - sync blocks and async calls and then executes them in a loop taking care of local variables and maintaining async call stack. The overhead is negligible for real functions.

## Usage

Async call must occupy one whole statement and this statement must be a statement in the parent expression and so up to top. That is you can use async in if, while, do, $(case), between ";" in a statement list but can't use it in the arguments of a function or as an element of a list/any expression:
```
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

where expression can be one of:
* fn arg
* fn[arg1;arg2;..]
* @[fn;arg;handler]
* .[fn;(arg1;..);handler]

and fn is one of:
* function name
* function itself - {...}, it can't be parted!
* local variable with the name/function

fn can be parted but only if it is used by name. 

Examples:
```
async .cron.delay 0D00:03
: async calc[x+1;10]
async v: @[.cep.split;msg;{...}]
```

You can use any function (type 100) with async keyword but only two types are not trivial:
* async functions - functions with async keyword.
* CPS functions (continuation passing style) - these are ordinary functions that have cont as the first argument: {[cont;..] }, where cont is the current continuation.

CPS functions are endpoints that store cont until the return value is ready. For example:
```
.cron.delay:{[cont;tm] .cron.addJob[... set fn to {.as.resume[x;::]}, arg to cont, time to .z.P+tm...]; :`async}
/ and in an async func
async .cron.delay 0D00:03; / returns after 3 min
```

Allowed return values:
* value - any Q value.
* exception - Q exception as well.
* \`async - terminate the current async call (it will be resumed later via a continuation).
* (\`asyncExc;value) - raise an exception, it can be caught by an async catch block.

Continuations:
* if you call them from an async/CPS function then you MUST immediately return their value: `: cont val`.
* otherwise call them via `.as.resume[cont;val]`. Resume can be called from an async fn too, it will start a new async loop.

## Exception blocks

You can use the usual Q try block with async:
```
async @[fn;arg;handler] / and all other variants with assign and return
async .[fn;args;handler]
```
handler shouldn't be async.

To raise an exception use ' or return (\`asyncExc;value) from an async/CPS function:
```
async { if[bad; :(`asyncExc;value)]; ..}[];
```

## Tail call elimination

As a bonus all async tail calls are eliminated. It means you can replace cycles/adverbs with recursive calls like:
```
cepLoop:{[a] / infinite recursive loop
  if[count msgs; process 1 msg; : async cepLoop[]];
  async .cron.wait 100;
  async cepLoop[]
 };
```
The call will be eliminated only if a) it is async b) it is the last expression or a return expression c) it is not an exception block.

## .z.s calls

You can use .z.s in async functions but only with async keyword (because .z.s is an async function):
```
{if[x>10; :x]; async .z.s x+1}
```

## Continuations

These are 100% genuine continuations. For example here is the (in)famous yinyang function that is notoriously hard to understand:
```
{async yin: {[cont;x] cont}[]; 1 "@"; async yang: {[cont;x] cont}[]; 1 "*"; : yin yang}
```
If you call a continuation from an async fn as above you MUST return its value.

To simplify the continuation capture in async functions there is callcc function (use CPS functions for non-async fns):
```
async .as.callcc[asyncFn;args];
...
asynFn:{[cont;args...] ...; async ...; : cont val};
```
