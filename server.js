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

//notasecret