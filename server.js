//SERVER
var express = require('express');
var app = express();


app.get('/', function (req, res) {
    res.render('index');
});

var server = app.listen(8000, function () {
    var host = server.address().address;
    var port = server.address().port;

    app.set('views', './views')
    app.set('view engine', 'jade');
    
    app.use(express.static('./dist'));

    console.log('Example app listening at http://%s:%s', host, port);
});



//DATABASE
var mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/test');

var db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function (callback) {
    // yay!
});


var kittySchema = mongoose.Schema({
    name: String
});

var Kitten = mongoose.model('Kitten', kittySchema);

var silence = new Kitten({name: 'Silence'});


silence.save(function (err, fluffy) {
    if (err) return console.error(err);
    silence.speak();
});

Kitten.find(function (err, kittens) {
  if (err) return console.error(err);
  console.log(kittens);
});

Kitten.find({ name: /^Silence/ }, callback);


//data store
//video search
//video sync
//chat