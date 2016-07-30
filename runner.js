var page = require('webpage').create();

var url = 'http://localhost:63342/shoreditch-ui-chrome/chrome/elm.html?_ijt=vtho1l6n4ofds75nmh22hbrhtp'

//shamelessly stolen from: https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
"use strict";
//TODO: remove the String support for functions ...
//TODO: rename id to stepId
//TODO: have a runId (and maybe stick all id's on context)
function waitFor(id, testFx, onReady, timeOutMillis) {
    var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3000, //< Default Max Timout is 3s
        start = new Date().getTime(),
        condition = false,
        interval = setInterval(function() {
//            console.log("looping...")
            if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
                // If not time-out yet and condition not yet fulfilled
                condition = (typeof(testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
            } else {
                if(!condition) {
                    // If condition still not fulfilled (timeout but condition is 'false')
//                    console.log("'waitFor()' timeout");
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

page.onConsoleMessage = function(msg, lineNum, sourceId) {
  console.log('CONSOLE: [' + msg + '] (from line #' + lineNum + ' in "' + sourceId + '")');
};

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
  console.log("> js received: " + JSON.stringify(word));

  //TODO: use JSON.stringify instead ...
  if (word.request.command == "click") { click(word.id, word.request.arg); }
  else if (word.request.command == "goto") { goto(word.id, url); }
  else if (word.request.command == "textContains") { textContains(word.id, word.request.arg); }
  else if (word.request.command == "close") { close(word.id); }

  //TODO: report(id, [""]) if command not found ...
});

//TODO: add start time, to capture duration ...
function report(id, result) {
  var result = { id:id, failures:result }
  console.log("> js sent: " + JSON.stringify(result));
  page.render('step-' + id + '.png')
  app.ports.suggestions.send(result);
}

//goto("1001", url);
//click("1002", "#refreshButton");
//textContains("1003", "#messageList");
//close("1004");

//TODO: have the app call back (via port) when ready .... or just assert something instead ...

function goto(id, url) {
//  console.log("### Goto(url)");
//  console.log(url);
  page.open(url, function(status) {
//    console.log(url);
//    console.log(status);
    if (status !== 'success') {
      report(id, ['Unable to access network'])
    } else {
      report(id, [])
    }
  });
}

function close(id) {
  report(id, [])
  page.close()
  phantom.exit()
}

function click(id, selector) {
  waitFor(id, function() {
    //condition
    return page.evaluate(function(theSelector) {
      //TODO: need to check unique etc
      console.log(theSelector)
      return $(theSelector).is(":visible");
    }, selector);

    //action
    }, function() {
      page.evaluate(function(theSelector) {
        $(theSelector).click();
      }, selector);
      //console.log("--> I clicked it");
    }
  );
}

function textContains(id, selector) {
//  console.log("### Assert(TextContains(id, value))");
  waitFor(id, function() {
    //condition
    return page.evaluate(function(theSelector) {
      //TODO: need to check unique etc
      return $(theSelector).is(":contains('ManualMetaDataRefresh')");
    }, selector);

    //action
    }, function() {
      //console.log("--> Text did contain it now.");
      //TODO: need an end test of something, but this should not be here ...
      //phantom.exit();
    }
  );
}