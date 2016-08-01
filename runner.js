var page = require('webpage').create();

//shamelessly stolen from: https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
"use strict";
//TODO: remove the String support for functions ...
//TODO: rename id to stepId
//TODO: have a runId (and maybe stick all id's on context)
//TODO: should screenshot be before the action - might be more useful for debug
//TODO: might be nice highlight the interactable element (like watir) before we do the action ...
//TODO: one server for all, or one per test? port numbers
//TODO: write the files somewhere useful, include the port-number perhaps ...
//TODO: do as much as possible in elm .. e.g. build the test report in elm, save it in js
//TODO: this script should have a return value of success of failure, for scripts to use ...
function waitFor(id, testFx, onReady, timeOutMillis) {
    var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3000, //< Default Max Timout is 3s
        start = new Date().getTime(),
        condition = false,
        interval = setInterval(function() {
            if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
                // If not time-out yet and condition not yet fulfilled
                condition = (typeof(testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
            } else {
                if(!condition) {
                    // If condition still not fulfilled (timeout but condition is 'false')
                    clearInterval(interval); //< Stop this interval
                    report(id, ["timeout"])
                } else {
                    // Condition fulfilled (timeout and/or condition is 'true')
//                    console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
                    typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
                    clearInterval(interval); //< Stop this interval
                    report(id, [])
                }
            }
        }, 250); //< repeat check every 250ms
};

//page.onConsoleMessage = function(msg, lineNum, sourceId) {
//  console.log('CONSOLE: [' + msg + '] (from line #' + lineNum + ' in "' + sourceId + '")');
//};

//var r = page.injectJs("tests.js") ? "... done injecting tests.js!" : "... fail! Check the $PWD?!";
//console.log(r);

//var x = page.evaluate(function() {
//  var result = test();
//  console.log(result);
//  return result;
//});
//
//console.log(x);

//TODO: definitely make this an argument ... maybe support multiple file inputs .... run if successful ... good for autotesting
//TODO: inject jquery ... (don't rely on being in the page itself ... or make it optional at least)
var r2 = phantom.injectJs("tests.js") ? "... done injecting elm.js!" : "... fail! Check the $PWD?!";
//console.log(r2);

//TODO: ultimately replace with worker();
//TODO: ultimately the module should probably be an arg
var app = Elm.DrivebyTest.fullscreen();

//TODO: fix this naming, its not check or word ...
app.ports.commands.subscribe(function(word) {
  if (word.request.command == "click") { click(word.id, word.request.args[0]); }
  //TODO: return the port in the response ... (or specify it on the way in)
  else if (word.request.command == "goto") { goto(word.id, word.request.args[0]); }
  else if (word.request.command == "textContains") { textContains(word.id, word.request.args[0], word.request.args[1]); }
  else if (word.request.command == "close") { close(word.id); }
  else if (word.request.command == "serve") { serve(word.id, word.request.args[0], word.request.args[1]); }
  else { report(word.id, ["don't know how to process command: " + JSON.stringify(word) ]); }
});

//TODO: add start time, to capture duration ...
function report(id, result) {
  var result = { id:id, failures:result }
//  console.log("> js sent: " + JSON.stringify(result));
  page.render('step-' + id + '.png')
  app.ports.suggestions.send(result);
}

//TODO: have the app call back (via port) when ready .... or just assert something instead ...

function goto(id, url) {
  page.open(url, function(status) {
    if (status !== 'success') {
      report(id, ['Unable to access network'])
    } else {
      report(id, [])
    }
  });
}

function click(id, selector) {
  waitFor(id, function() {
    //condition
    return page.evaluate(function(theSelector) {
      //TODO: need to check unique etc
      //TODO: pull out as findUniqueInteractable
      return $(theSelector).is(":visible");
    }, selector);

    //action
    }, function() {
      page.evaluate(function(theSelector) {
        $(theSelector).click();
      }, selector);
    }
  );
}

//TODO: asserts() will always look a bit like this
function textContains(id, selector, expected) {
  waitFor(id, function() {
    //condition
    return page.evaluate(function(theSelector, theExpected) {
      //TODO: need to check unique etc
      //TODO: pull out as findUnique
      return $(theSelector).is(":contains('" + theExpected + "')");
    }, selector, expected);

    //action
    }, function() {
    }
  );
}

function close(id) {
  report(id, [])
  page.close()
  //TODO: pull out a separate exit
  phantom.exit()
}

function serve(id, path, port) {
    server = require('webserver').create();
    var fs = require('fs')

    service = server.listen(port, { keepAlive: true }, function (request, response) {
        fqn = path + request.url;
//        console.log('Request at ' + new Date());
//        console.log('### ' + request.url);
//        console.log(fqn);

        //TODO: if file doesnt exist then 404 instead ...
//        if (fs.exists(path))

        body = fs.read(fqn);
        response.statusCode = 200;
        response.headers = {
            'Cache': 'no-cache',
            //TODO: should probably base this on filetype ..
            'Content-Type': 'text/html',
            'Connection': 'Keep-Alive',
            'Keep-Alive': 'timeout=5, max=100',
            'Content-Length': body.length
        };

        response.write(body);
        response.close();
    });

    if (service) {
//        console.log('Web server running on port ' + port);
        //    console.log(path)
    } else {
        console.log('Error: Could not create web server listening on port ' + port);
        phantom.exit();
    }

  report(id, [])
}

page.onError = function(msg, trace) {
//TODO: append these to a file in the result dir ....
//  var msgStack = ['PHANTOM ERROR: ' + msg];
//  if (trace && trace.length) {
//    msgStack.push('TRACE:');
//    trace.forEach(function(t) {
//      msgStack.push(' -> ' + (t.file || t.sourceURL) + ': ' + t.line + (t.function ? ' (in function ' + t.function +')' : ''));
//    });
//  }
//  console.error(msgStack.join('\n'));
//  phantom.exit(1);
};