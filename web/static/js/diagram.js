// Time series diagram using the metricgraphics 2.7

// install the callback to the data_graphic function via an Elm port
function set_diagram_port(port) {
  console.log("subscribe to the diagram_port: " + port);
  port.subscribe(graph_options => {
    console.log("new graph options for rendering: " + graph_options);
    //graph_options.utc_time =true;
    var d = convert_dates(graph_options.data); // MG.convert.date(graph_options.data, 'date', '%Y-%m-%dT%X.%L%Z');
    graph_options.data = d;
    console.log("converted data");
    console.log(graph_options.data);
    try {
      return MG.data_graphic(graph_options);
    } catch (e) {
      console.warn("Got Exception inside MG.data_graphic");
      console.warn(e);
      return true;
    };
  });
};

function convert_dates(data) {
  var ds = [];
  console.log("Convert Dates for");
  console.log(data);
  data.forEach(function(d, index, array) {
    var new_date = new Date(d.date);
    ds.push({date: new_date, value: d.value});
  });
  return ds;
}

function data_generator(length)  {
  var d = new Date();
  var v = 100000;
  var data = [];
  var seconds = 5;
  for (var i = 0; i < length; i++) {
    v += (Math.random() - 0.5) * 10000;
    data.push({date: MG.clone(d), value: v});
    d = new Date(d.getTime() + seconds * 1000);
  }
  return data;
};

function sample_graph(){
  var timedData = data_generator(10);

  // var svg = d3.select(counterDiv); 
  console.log("timedData is" + timedData)
  return MG.data_graphic({
      title: "Tick Counter",
      show_tooltips: false,
      data: timedData,
      target: '#counterChart',
      width: 600,
      height: 200,
      right: 40
  });
};

export {sample_graph, set_diagram_port};