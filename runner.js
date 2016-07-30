var page = require('webpage').create();

//shamelessly stolen from: https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
"use strict";
//TODO: remove the String support for functions ...
//TODO: rename id to stepId
//TODO: have a runId (and maybe stick all id's on context)
//TODO: should screenshot be before the action - might be more useful for debug
//TODO: might be nice highlight the interactable element (like watir) before we do the action ...
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

//TODO: make this an argument ...
//TODO: make the .html of the app an an argument too ... (actually be separate)
//TODO: inject jquery ... (don't rely on being in the page itself ... or make it optional at least)
var r2 = phantom.injectJs("tests.js") ? "... done injecting elm.js!" : "... fail! Check the $PWD?!";
console.log(r2);

//TODO: ultimately replace with worker();
var app = Elm.Spelling.fullscreen();

app.ports.check.subscribe(function(word) {
//  console.log("> js received: " + JSON.stringify(word));
  if (word.request.command == "click") { click(word.id, word.request.arg); }
  //TODO: return the port in the response ... (or specify it on the way in)
  else if (word.request.command == "goto") { goto(word.id, 'http://localhost:8080/elm.html'); }
  else if (word.request.command == "textContains") { textContains(word.id, word.request.arg, "ManualMetaDataRefresh"); }
  else if (word.request.command == "close") { close(word.id); }
  else if (word.request.command == "serve") { serve(word.id, word.request.arg); }
  else { report(word.id, ["don't know how to process: " + word.request.command] ); }

  //TODO: report(id, ["failure"]) if command not found ...
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

function serve(id, path) {
    port = "8080";
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
        console.log('Web server running on port ' + port);
        //    console.log(path)
    } else {
        console.log('Error: Could not create web server listening on port ' + port);
        phantom.exit();
    }

  report(id, [])
}