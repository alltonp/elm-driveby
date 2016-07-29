var page = require('webpage').create();

var url = 'http://localhost:63342/shoreditch-ui-chrome/chrome/elm.html?_ijt=h3moocbtvst5imfp2uj59n2fs7'

//shamelessly stolen from: https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
"use strict";
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
                    console.log("'waitFor()' timeout");
                    clearInterval(interval); //< Stop this interval
                    report(id, ["timeout"])
                } else {
                    // Condition fulfilled (timeout and/or condition is 'true')
                    console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
                    typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
                    clearInterval(interval); //< Stop this interval
                    report(id, [])
                }
            }
        }, 250); //< repeat check every 250ms
};

page.onConsoleMessage = function(msg, lineNum, sourceId) {
  console.log('CONSOLE: ' + msg + ' (from line #' + lineNum + ' in "' + sourceId + '")');
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
//TODO: inject jquery ...
var r2 = phantom.injectJs("tests.js") ? "... done injecting elm.js!" : "... fail! Check the $PWD?!";
console.log(r2);

var app = Elm.Spelling.fullscreen();

//console.log("Running elm ...");

app.ports.check.subscribe(function(word) {
  console.log("Message in: " + JSON.stringify(word));

  if (word.command == "click") { click(word.id, '"' + word.arg + '"'); }
  else if (word.command == "goto") { goto(word.id, url); }

  //TODO: report(id, [""]) if command not found ...
});

function report(id, result) {
  var result = { id:id, failures:result }
  console.log("Message out: " + JSON.stringify(result));
  page.render('step-' + id + '.png')
  app.ports.suggestions.send(result);
}



//page.open(url, function(status) {
//  if (status !== 'success') {
//    console.log('Unable to access network');
//  } else {

        //STEP 1 - Goto(url)
        //waitFor(function() {
          //condition
          //return
          //val r =
//          console.log("### Goto(url)");
//          page.open(url, function(status) {
//              if (status !== 'success') {
//                console.log('Unable to access network');
//                //return false
//              } else {
//                console.log('--> I went to ...');
//                //return true
//              }
//          });
//          page.render('step-1.png')

          //action
          //}, function() {
          //   console.log("url should be visible now.");
          //});

        goto("1001", url);
        click("1002", "#refreshButton");
//        console.log("click was called in inlne")
//        console.log(c.length)

        //STEP 3 - Assert(TextContains(id, value))
        console.log("### Assert(TextContains(id, value))");
        waitFor("1003", function() {
          //condition
          return page.evaluate(function() {
              //TODO: need to check unique etc
              return $("#messageList").is(":contains('ManualMetaDataRefresh')");
          });

          //action
          }, function() {
             console.log("--> Text did contain it now.");
             //page.render('step-3.png')
             //TODO: need an end test of something, but this should not be here ...
             //phantom.exit();
          });
//    }
//});

//TODO: have the app call back (via port) when ready .... or just assert something instead ...

function goto(id, url) {
  console.log("### Goto(url)");
  console.log(url);
  page.open(url, function(status) {
      if (status !== 'success') {
        console.log('Unable to access network');
        report(id, ['Unable to access network'])
      } else {
        console.log('--> I went to ...');
        report(id, [])
        //return true
      }
  });
  //page.render('step-1.png')
}

function click(id, selector) {
    waitFor(id, function() {

      //condition
      return page.evaluate(function(theSelector) {
          //TODO: need to check unique etc
          return $(theSelector).is(":visible");
      }, selector);

      //action
      }, function() {
         page.evaluate(function(theSelector) {
            $(theSelector).click();
         }, selector);

         console.log("--> I clicked it");
      });

//  console.log("click() returning")
//  console.log(r.length)
//  return r(function (x) {
//             console.log(x);
//           });
//    return r;
}

