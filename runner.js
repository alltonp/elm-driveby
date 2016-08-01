//TODO: make it so that each command can report it's duration
var started = new Date().getTime();

var page = require('webpage').create();

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
function waitFor(id, testFx, onReady, timeOutMillis) {
    var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3000, //TODO: make this a config option
        start = new Date().getTime(),
        condition = false,
        interval = setInterval(function() {
            if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
                condition = testFx();
            } else {
                if (!condition) {
                    clearInterval(interval);
                    report(id, ["timeout"]);
                } else {
                    onReady();
                    clearInterval(interval);
                    report(id, []);
                }
            }
        }, 1); //TODO: make this a config option

};

//TODO: make this a config option
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

//TODO: definitely make this an argument ... maybe support multiple file inputs .... run if successful ... good for autotesting
//TODO: inject jquery ... (don't rely on being in the page itself ... or make it optional at least)
var r2 = phantom.injectJs("tests.js") ? "... done injecting elm.js!" : "... fail! Check the $PWD?!";
//console.log(r2);

//TODO: ultimately the module should probably be an arg
var app = Elm.DrivebyTest.worker();

//TODO: ideally take a command here ... or maybe have step.context
//TODO: ultimately have a config message come through here ... be useful to be able to change it on the fly
app.ports.commands.subscribe(function(step) {
  if (step.command.name == "click") { click(step.id, step.command.args[0]); }
  else if (step.command.name == "enter") { enter(step.id, step.command.args[0], step.command.args[1]); }
  else if (step.command.name == "goto") { goto(step.id, step.command.args[0]); }
  else if (step.command.name == "textContains") { textContains(step.id, step.command.args[0], step.command.args[1]); }
  else if (step.command.name == "close") { close(step.id); }
  else if (step.command.name == "serve") { serve(step.id, step.command.args[0], step.command.args[1]); }
  else { report(step.id, ["don't know how to process command: " + JSON.stringify(step) ]); }
});

//TODO: add start time, to capture duration ...
//TODO: rename to notifyElm or something ...
function report(id, result) {
  var result = { id:id, failures:result }
//  console.log("> js sent: " + JSON.stringify(result));
  //TODO: make this a config option
  page.render('step-' + id + '.png')
  app.ports.results.send(result);
}

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
      //TODO: pull out as findUniqueInteractable
      //TODO: make this a condition
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
function enter(id, selector, value) {
  waitFor(id, function() {
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
function textContains(id, selector, expected) {
  waitFor(id, function() {
    //condition
    return page.evaluate(function(theSelector, theExpected) {
      //TODO: pull out as findUnique
      var e = $(theSelector)
      return e.length == 1 && e.is(":contains('" + theExpected + "')");
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
  console.log("Done " + (new Date().getTime() - started) + "ms.");
  phantom.exit()
}

function serve(id, path, port) {
    var server = require('webserver').create();
    var fs = require('fs')

    var service = server.listen(port, { keepAlive: true }, function (request, response) {
        var fqn = path + request.url;
//        console.log('Request at ' + new Date());
//        console.log('### ' + request.url);
//        console.log(fqn);

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

  report(id, [])
}

//TODO: make this an option to report/surppress errors in config
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