var page = require('webpage').create();

var url = 'http://localhost:63342/shoreditch-ui-chrome/chrome/elm.html?_ijt=91icvtf1lk5kcg6a3c9unf6k79'

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

var x = page.evaluate(function() {
  console.log("### checking we can call injected");
  var result = test();
  console.log(result);
  return result
});

console.log(x);


//page.open(url, function(status) {
//  if (status !== 'success') {
//    console.log('Unable to access network');
//  } else {

        //STEP 1 - Goto(url)
        //waitFor(function() {
          //condition
          //return
          //val r =
          console.log("### Goto(url)");
          page.open(url, function(status) {
              if (status !== 'success') {
                console.log('Unable to access network');
                //return false
              } else {
                console.log('--> I went to ...');
                //return true
              }
          });
          page.render('step-1.png')

          //action
          //}, function() {
          //   console.log("url should be visible now.");
          //});


        //STEP 2 - Click(id)
        console.log("### Click(id)");
        waitFor(function() {
          //condition
          return page.evaluate(function() {
              //TODO: need to check unique etc
              return $("#refreshButton").is(":visible");
          });

          //action
          }, function() {
//             console.log("Element should be visible now.");
             page.evaluate(function() {
                $("#refreshButton").click();
             });
             page.render('step-2.png')
             console.log("--> I clicked it");
             //console.log(page.plainText);
             //phantom.exit();
          });

        //STEP 3 - Assert(TextContains(id, value))
        console.log("### Assert(TextContains(id, value))");
        waitFor(function() {
          //condition
          return page.evaluate(function() {
              //TODO: need to check unique etc
              return $("#messageList").is(":contains('ManualMetaDataRefresh')");
          });

          //action
          }, function() {
             console.log("--> Text did contain it now.");
             page.render('step-3.png')
             phantom.exit();
          });
//    }
//});

//TODO: have the app call back (via port) when ready .... or just assert something instead ...

