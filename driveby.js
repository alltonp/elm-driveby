//TODO: make this the main script https://github.com/ariya/phantomjs/blob/master/examples/arguments.js
//TODO: this looks good for parallel - https://github.com/ariya/phantomjs/blob/master/examples/child_process-examples.js
//TODO: implement a tuplespace in elm?
//TODO: in larger test suites we will defo want to unserver at the end of each script
//TODO: consider running this as a daemon/server and connect to it .. a-la flyby .. and shorter start time

//TODO: make it so that each command can report it's duration
var started = new Date().getTime();

//TODO: rename to browsers
var pages = [];
var stubs = {};

//TODO: put this in arg[] to this script ..
var numberOfBrowsers = 4;
var nextPort = 9000;

for (var i = 0; i < numberOfBrowsers; i+=1) {
    var p = require('webpage').create();

    //TODO: make this a config option - surpress action logging
    p.onConsoleMessage = function(msg, lineNum, sourceId) {
      console.log('CONSOLE: [' + msg + '] (from line #' + lineNum + ' in "' + sourceId + '")');
    };

    //TODO: make this an option to report/surppress page errors in config
    //TIP: surpressed if this code is here ..
    var surpress = true;

    if (surpress) {
        p.onError = function(msg, trace) {
    //    TODO: append these to a file in the result dir ....
        };
    }

    pages.push(p);
}

//console.log(pages.length)

//var page = pages[0];

//shamelessly stolen from: https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
"use strict";
//TODO: rename id to stepId
//TODO: have a runId (and maybe stick all id's on context)
//TODO: should screenshot be before the action - might be more useful for debug
//TODO: might be nice highlight the interactable element (like watir) before we do the action ...
//TODO: one server for all, or one per test? port numbers
//TODO: write the files somewhere useful, include the port-number perhaps ...
//TODO: do as much as possible in elm .. e.g. build the test report in elm, save it in js
//TODO: this script should have a return value of success of failure, for scripts to use ...
//TODO: rename functions and condition to be more readable
//TODO: consider running this as a daemon
//TODO: this waiting could be in elm ... would possibly need to subscribe to time
//TODO: changes to this file should also trigger autotest.sh
function waitFor(context, id, testFx, onReady, onFail, timeOutMillis) {
    var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3000, //TODO: make this a config option
        start = new Date().getTime(),
        condition = false,
        interval = setInterval(function() {
            if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
                condition = testFx();
            } else {
                if (!condition) {
                    clearInterval(interval);
                    respond(context, id, [onFail()]);
                } else {
                    onReady();
                    clearInterval(interval);
                    respond(context, id, []);
                }
            }
        }, 1); //TODO: make this a config option

};

//var r = page.injectJs("tests.js") ? "... done injecting tests.js!" : "... fail! Check the PWD?!";
//console.log(r);

//var x = page.evaluate(function() {
//  var result = test();
//  console.log(result);
//  return result;
//});
//
//console.log(x);

//TODO: definitely make this an argv ... maybe support multiple file inputs .... run if successful ... good for autotesting
//TODO: inject jquery ... (don't rely on being in the page itself ... or make it optional at least)
var r2 = phantom.injectJs("tests.js") ? "... done injecting elm.js!" : "... fail! Check the PWD?!";
//console.log(r2);

var flags = { numberOfBrowsers: pages.length };
var unused = document.createElement('div');
var app = Elm.DrivebyTest.embed(unused, flags);

//TODO: ideally take a command here ... or maybe have step.context
//TODO: ultimately have a config message come through here ... be useful to be able to change it on the fly
app.ports.requests.subscribe(function(request) {
  var command = request.step.command
  var name = command.name
  var id = request.step.id
  var context = request.context
  var page = pages[context.browserId]

  if (name == "click") { click(page, context, id, command.args[0]); }
  else if (name == "enter") { enter(page, context, id, command.args[0], command.args[1]); }
  else if (name == "goto") { goto(page, context, id, command.args[0]); }
  else if (name == "gotoLocal") { goto(page, context, id, "http://localhost:" + context.localPort + command.args[0]); }
  else if (name == "assert") { assert(page, context, id, command.args[1], command.args[0], command.args[2]); }
//  else if (name == "textContains") { assert(page, context, id, command.args[0], "textContains", command.args[1]); }
//  else if (name == "textEquals") { assert(page, context, id, command.args[0], "textEquals", command.args[1]); }
  else if (name == "close") { close(page, context, id); }
  else if (name == "serve") { serve(context, id, command.args[0], context.localPort); }
  else if (name == "stub") { stub(context, id, command.args[0], command.args[1], context.localPort); }
  else if (name == "init") { init(context, id); }
  else { respond(context, id, ["don't know how to process request: " + JSON.stringify(request) ]); }
});

//var config = { browsers:pages.length }
//app.ports.responses.send(config);

//TODO: add start time, to capture duration ...
//TODO: rename to notifyElm or something ...
function respond(context, id, failures) {
  var y = Date.now()
//  console.log(y)
//  var x = y.toISOString()
//  console.log(x)
  var response = { context:context, failures:failures, updated:y }
  //TODO: make this a config option
  //TODO: and actually this is probably the wrong place for it. because some commmands don't want it...
  //page.render('step-' + id + '.png')
  app.ports.responses.send(response);
}


function init(context, id) {
  context.localPort = nextPort;
  nextPort = nextPort + 1;
  respond(context, id, [])
}


function goto(page, context, id, url) {
  page.open(url, function(status) {
    if (status !== 'success') {
      respond(context, id, ['Unable to access network'])
    } else {
      respond(context, id, [])
    }
  });
}

//TIP: http://stackoverflow.com/questions/15739263/phantomjs-click-an-element
function click(page, context, id, selector) {
  waitFor(context, id, function() { return isUniqueInteractable(page, selector); }
    //action
    , function() {
      page.evaluate(function(theSelector) {
        //TODO: kill this $
//        $(theSelector).click();
        document.querySelector(theSelector).click();
      }, selector);
    },
    function() { return describeFailure(page, selector); }
  );
}

//TODO: consider casper ... http://docs.casperjs.org/en/latest/modules/casper.html#options
function enter(page, context, id, selector, value) {
  waitFor(context, id, function() { return isUniqueInteractable(page, selector); }
      //action
      , function() {
        page.evaluate(function(theSelector, theValue) {
          //TODO: kill this $
          e = $(theSelector)

        //TODO: if clear .. but not firing events properly .. backspace maybe
//        e.val("");

        //TODO: struggling to put cursor in correct place .. why is that?
//        e.setCursorPosition(e.val().length);
//        e.setSelectionRange(10, 20);
          e.focus();

//        e.selectionStart = 10;
//        e.selectionEndt = 20;
//        var range = e.createTextRange();
//                    range.collapse(true);
//                    range.moveEnd('character', 10);
//                    range.moveStart('character', 10);
//                    range.select();

//        $(theSelector).val("");
//        $(theSelector).change();
//        console.log(theValue);
//        thePage.sendEvent('keypress', theValue);
//        console.log($(theSelector).val);
        }, selector, value);

      //TODO: this does seem to work if it is not empty ...
//      page.sendEvent('keypress', page.event.key.Backspace);
        page.sendEvent('keypress', value);
    },
    function() { return describeFailure(page, selector); }
  );
}

//TIP: these will be useful for asserts - https://api.jquery.com/category/selectors/
//TIP: and performance - https://api.jquery.com/filter/
//TODO: factor out duplication
//TODO: can we do more of this in elm land?
//TODO: make main function return a true/false and an error message, or a function for the error instead ...
function assert(page, context, id, selector, condition, expected) {
  if (condition == "textContains") {
    return assertCondition(page, context, id, selector, expected, function(e, theExpected) {
        return e.length == 1 && e[0].textContent.indexOf(theExpected) >= 0;
    });
  }
  else if (condition == "textEquals") {
    return assertCondition(page, context, id, selector, expected, function(e, theExpected) {
        return e.length == 1 && e[0].textContent == theExpected;
    });
  }
  else { respond(context, id, ["don't know how to process condition: " + JSON.stringify(condition) ]); }
}

function assertCondition(page, context, id, selector, expected, conditionFunc) {
  waitFor(context, id,
    function() { //condition
      return page.evaluate(function(theSelector, theExpected, theConditionFunc) {
        return theConditionFunc(document.querySelectorAll(theSelector), theExpected);
      }, selector, expected, conditionFunc);
    }, function() { } //action
    , function() { //failure
      return page.evaluate(function(theSelector, theExpected) {
        var e = document.querySelectorAll(theSelector);
        if (e.length != 1) {
          return "expected 1 for " + theSelector + " but found " + e.length;
        } else {
          //TODO: we need description function in here too
          //TODO: and generate the butWas ...
          return "expected " + theSelector + " to ??? " + theExpected + " but was " + e[0].textContent;
        }
      }, selector, expected);
    }
  );
}

//TIP: http://stackoverflow.com/questions/19669786/check-if-element-is-visible-in-dom
function isUniqueInteractable(page, selector) {
  return page.evaluate(function(theSelector) {
    var e = document.querySelectorAll(theSelector)
    return e.length == 1 && !!( e[0].offsetWidth || e[0].offsetHeight || e[0].getClientRects().length ); // aka visible
  }, selector);
}

//TIP: give me a better name .. or support an optional assert or something .. who knows
function describeFailure(page, selector) {
  return page.evaluate(function(theSelector) {
    var e = document.querySelectorAll(theSelector);
    return "expected 1 element for " + theSelector + " but found " + e.length;
  }, selector);
}

function close(page, context, id) {
  respond(context, id, [])
  page.close()
  //TODO: pull out a separate exit
  console.log("Done " + (new Date().getTime() - started) + "ms.");
  phantom.exit()
}

function stub(context, id, path, content, port) {
  stubs[(port + ":" + path)] = content;
  respond(context, id, [])
}

function serve(context, id, path, port) {
  var server = require('webserver').create();
  var fs = require('fs')

  var service = server.listen(port, { keepAlive: true }, function (request, response) {
    var fqn = path + request.url;
    var key = port + ":" + request.url

    //TODO: better handle fqn?queryString
    if (stubs[key] !== undefined) {
      r = {body: stubs[key], code: 200}
    } else if (fs.exists(fqn)) {
      r = {body: fs.read(fqn), code: 200}
    } else {
      r = {body: "", code: 404}
    }

    response.statusCode = r.code;
    response.headers = {
        'Cache': 'no-cache', 'Content-Length': r.body.length,
        'Content-Type': 'text/html' //TODO: c/should probably base this on filetype ..
    };
    response.write(r.body);
    response.close();
  });

  if (!service) {
    console.log('Error: Could not create web server listening on port ' + port);
    phantom.exit();
  }

  respond(context, id, [])
}