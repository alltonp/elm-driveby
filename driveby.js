//TODO: make this the main script https://github.com/ariya/phantomjs/blob/master/examples/arguments.js
//TODO: this looks good for parallel - https://github.com/ariya/phantomjs/blob/master/examples/child_process-examples.js
//TODO: instantiate multiple 'page's and stash them away ... implement a tuplespace in elm?

//TODO: make it so that each command can report it's duration
var started = new Date().getTime();

//TODO: rename to browsers
var pages = [];
var browserCount = 4;

//TODO: put this in arg[] to this script ..
for (var i = 0; i < browserCount; i+=1) {
    var p = require('webpage').create();

    //TODO: make this a config option - surpress action logging
    p.onConsoleMessage = function(msg, lineNum, sourceId) {
      console.log('CONSOLE: [' + msg + '] (from line #' + lineNum + ' in "' + sourceId + '")');
    };

    //TODO: make this an option to report/surppress page errors in config
    p.onError = function(msg, trace) {
    //TODO: append these to a file in the result dir ....
    };

//    console.log(p)
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
function waitFor(context, id, testFx, onReady, timeOutMillis) {
    var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3000, //TODO: make this a config option
        start = new Date().getTime(),
        condition = false,
        interval = setInterval(function() {
            if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
                condition = testFx();
            } else {
                if (!condition) {
                    clearInterval(interval);
                    respond(context, id, ["timeout"]);
                } else {
                    onReady();
                    clearInterval(interval);
                    respond(context, id, []);
                }
            }
        }, 1); //TODO: make this a config option

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

//TODO: definitely make this an argv ... maybe support multiple file inputs .... run if successful ... good for autotesting
//TODO: inject jquery ... (don't rely on being in the page itself ... or make it optional at least)
var r2 = phantom.injectJs("tests.js") ? "... done injecting elm.js!" : "... fail! Check the $PWD?!";
//console.log(r2);

var flags = { browsers: pages.length };
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
  else if (name == "gotoLocal") { goto(page, context, id, "http://localhost:" + command.args[0]); }
  else if (name == "textContains") { textContains(page, context, id, command.args[0], command.args[1]); }
  else if (name == "close") { close(page, context, id); }
  else if (name == "serve") { serve(context, id, command.args[0], command.args[1]); }
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
  var response = { context:context, id:id, failures:failures, updated:y }
  //TODO: make this a config option
  //TODO: and actually this is probably the wrong place for it. because some commmands don't want it...
  //page.render('step-' + id + '.png')
  app.ports.responses.send(response);
}

//TODO: I dont seem to fail nicely, e.g. hang on bad url
function goto(page, context, id, url) {
  page.open(url, function(status) {
    if (status !== 'success') {
      respond(context, id, ['Unable to access network'])
    } else {
      respond(context, id, [])
    }
  });
}

function click(page, context, id, selector) {
  waitFor(context, id, function() {
    //condition
    return page.evaluate(function(theSelector) {
      //TODO: pull out as findUniqueInteractable
      //TODO: make this a condition
      //TODO: if trying to lose jquery ... could use: document.getElementById
      var e = $(theSelector)
      return e.length == 1 && e.is(":visible");
      //TODO: need butWas()
    }, selector);

    //action
    }, function() {
      page.evaluate(function(theSelector) {
        $(theSelector).click();
      }, selector);
    }
  );
}

//TODO: consider casper ... http://docs.casperjs.org/en/latest/modules/casper.html#options
function enter(page, context, id, selector, value) {
  waitFor(context, id, function() {
    //condition
    return page.evaluate(function(theSelector) {
      //TODO: pull out as findUniqueInteractable
      //TODO: make this a condition
      var e = $(theSelector)
      return e.length == 1 && e.is(":visible");
      //TODO: need butWas()
    }, selector);

    //action
    }, function() {
      page.evaluate(function(theSelector, theValue) {
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
    }
  );
}

//TIP: these will be useful for asserts - https://api.jquery.com/category/selectors/
//TIP: and performance - https://api.jquery.com/filter/

//TODO: asserts() will always look a bit like this
function textContains(page, context, id, selector, expected) {
  waitFor(context, id, function() {
    //condition
    return page.evaluate(function(theSelector, theExpected) {
      //TODO: pull out as findUnique
      var e = $(theSelector)
      return e.length == 1 && e.is(":contains('" + theExpected + "')");
    }, selector, expected);

    //action
    }, function() {}
  );
}

function close(page, context, id) {
  respond(context, id, [])
  page.close()
  //TODO: pull out a separate exit
  console.log("Done " + (new Date().getTime() - started) + "ms.");
  phantom.exit()
}

function serve(context, id, path, port) {
    var server = require('webserver').create();
    var fs = require('fs')

    var service = server.listen(port, { keepAlive: true }, function (request, response) {
        var fqn = path + request.url;

        //TODO: if file doesnt exist then 404 instead ...
//        if (fs.exists(path))

        var body = fs.read(fqn);
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

  respond(context, id, [])
}
