// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "deps/phoenix_html/web/static/js/phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket";
// import D3 from "web/static/vendor/d3.js";
import sample_graph from "./diagram";

// connect with our Elm main module `Elm.Dash`
var elmDiv = document.getElementById('elm-main')
	, initialPortState = {getCounterValue: 0}
    , elmApp = Elm.embed(Elm.Dash, elmDiv, initialPortState);

// join channel and set initial state
console.log("Connect to counters:lobby")
let channel = socket.channel("counters:lobby", {})
channel.join()
  .receive("ok", counter => {
  	console.log("Send 'getCounterValue' the counter value: ", counter);
  	console.log("the ports are: ", elmApp.ports);
  	// elmApp.ports.getCounterValue.send(counter);
	})
  .receive("error", resp => console.log("Unable to join", resp));

// elm ports
// Send a new value to phoenix
elmApp.ports.sendValuePort.subscribe(value => {
	console.log("send value to phoenix: ", value);
  channel.push("set_value", value)
         .receive("error", payload => console.log(payload.message))
});
// receive a new model history from Elm
elmApp.ports.sendHistoryPort.subscribe(history => {
  console.log("got history from Elm: ", history);
  
});
// get a counter value and send it to Elm
channel.on("getCounterValue", counter => {
	console.log("getCounterValue from Phoenix: ", counter);
	elmApp.ports.getCounterValue.send(counter.value)}
	);

// Graphics
sample_graph();
