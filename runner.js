var page = require('webpage').create();

var url = 'http://localhost:63342/shoreditch-ui-chrome/chrome/elm.html?_ijt=tlhi3gt4odl60m55ldomau69t9'

//shamelessly stolen from: https://github.com/ariya/phantomjs/blob/master/examples/waitfor.js
"use strict";
function waitFor(testFx, onReady, timeOutMillis) {
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
                    console.log("'waitFor()' timeout");
                    phantom.exit(1);
                } else {
                    // Condition fulfilled (timeout and/or condition is 'true')
                    console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
                    typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
                    clearInterval(interval); //< Stop this interval
                }
            }
        }, 250); //< repeat check every 250ms
};

var r = page.injectJs("tests.js") ? "... done injecting itself!" : "... fail! Check the $PWD?!";
console.log(r);

page.evaluate(function() {
  test();
});


page.open(url, function(status) {
  if (status !== 'success') {
    console.log('Unable to access network');
  } else {

        page.render('step-0.png')

        //STEP 1 - Click(id)
        waitFor(function() {
          //condition
          return page.evaluate(function() {
              //TODO: need to check unique etc
              return $("#refreshButton").is(":visible");
          });

          //action
          }, function() {
             console.log("Element should be visible now.");
             page.evaluate(function() {
                $("#refreshButton").click();
             });
             page.render('step-1.png')
             console.log("I clicked it");
             console.log(page.plainText);
             //phantom.exit();
          });

        //STEP 2 - Assert(TextContains(id))
        waitFor(function() {
          //condition
          return page.evaluate(function() {
              //TODO: need to check unique etc
              return $("#messageList").is(":contains('ManualMetaDataRefresh')");
          });

          //action
          }, function() {
             console.log("Text did contain it now.");
             page.render('step-2.png')
             phantom.exit();
          });
    }
});

//TODO: have the app call back (via port) when ready .... or just assert something instead ...

