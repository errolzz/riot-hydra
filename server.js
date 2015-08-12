
//SERVER
var express = require('express');
var bparser = require('body-parser');
var https = require('https');
var app = express();

var server = app.listen(8000, function () {
    var host = server.address().address;
    var port = server.address().port;

    app.set('views', './views')
    app.set('view engine', 'jade');
    
    app.use(bparser.urlencoded({extended: true}));
    app.use(bparser.json());
    app.use(express.static('./dist'));


    //API
    //sign in
    app.post('/signin', function (req, res) {
        //verify token is valid
        https.get('https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=' + req.body.token, function(response) {
            //console.log("statusCode: ", res.statusCode);

            response.on('data', function(d) {
                var parsed = JSON.parse(d);
                //verify client id matches
                if(parsed.aud == '325125235792-vosk7ah47madtojr3lemn49i631n3n1h.apps.googleusercontent.com') {
                    //send back unique google id
                    res.send({googleId: parsed.sub});
                } else {
                    res.send({googleId: null});
                }
            });
        }).on('error', function(e) {
            console.error(e);
        });
    });

    //get all rooms
    app.get('/api/rooms', function (req, res) {
        return Room.find(function (err, rooms) {
            if (!err) {
                return res.send(rooms);
            } else {
                return console.log(err);
            }
        });
    });

    //get a room
    app.get('/api/rooms/:id', function (req, res) {
        
    });

    //create a room
    app.post('/api/rooms', function (req, res) {
        var room = new Room({
            name:           req.body.name,
            nameLower:      req.body.name.toLowerCase(),
            open:           req.body.open,
            audience:       req.body.audience,
            djs:            req.body.djs
        });
        room.save(function (err) {
            if (!err) {
                return console.log('created');
            } else {
              return console.log(err);
            }
        });
        return res.send(room);
    });

    //update a rooms users
    app.put('/api/roomusers/:id', function (req, res) {
        return Room.findById(req.params.id, function (err, room) {

            //update room aud and djs
            room.audience =     req.body.audience;
            room.djs =          req.body.djs;

            if(room.audience.length + room.djs.length == 0) {
                //if room is now empty, delete it
                return room.remove(function (err) {
                    if (!err) {
                        console.log('removed');
                        return res.send({removed: true});
                    } else {
                        console.log(err);
                    }
                });
            } else {
                //save room with updated users
                return room.save(function (err) {
                    if (!err) {
                        console.log('updated')
                        return res.send(room);
                    } else {
                        console.log(err);
                    }
                    return res.send(room);
                });
            }
        });
    });

    app.get('/api/users', function (req, res) {
        return User.find(function (err, users) {
            if (!err) {
                return res.send(users);
            } else {
                return console.log(err);
            }
        });
    });

    //get a user by googleid
    app.get('/api/users/:googleid', function (req, res) {
        return User.findOne({googleId: req.params.googleid}, function (err, user) {
            user = user || {googleId: null};
            if (!err) {
                return res.send(user);
            } else {
                return console.log(err);
            }
        });
    });

    //get a user by name
    app.get('/api/checkname/:name', function (req, res) {
        var ln = decodeURIComponent(req.params.name).toLowerCase();
        return User.findOne({nameLower: ln}, function (err, user) {
            user = user || {name: null};
            if (!err) {
                return res.send(user);
            } else {
                return console.log(err);
            }
        });
    });

    //create a user
    app.post('/api/users', function (req, res) {
        
        var user = new User({
            googleId:   req.body.googleId,
            name:       req.body.name,
            nameLower:  req.body.name.toLowerCase()
        });
        
        user.save(function (err) {
            if (!err) {
                return console.log('created');
            } else {
              return console.log(err);
            }
        });
        return res.send(user);
    });

    console.log('Example app listening at http://%s:%s', host, port);
});

//ROUTES
app.get('/', function (req, res) {
    res.render('index');
});



//DATABASE
var mongoose = require('mongoose');
var options = { server: { socketOptions: { keepAlive: 1, connectTimeoutMS: 30000 } }, 
                replset: { socketOptions: { keepAlive: 1, connectTimeoutMS : 30000 } } };
mongoose.connect('mongodb://localhost/hydra', options); //DEV


var userSchema = mongoose.Schema({
    googleId:   {type: String, unique: true, required: true},
    name:       {type: String, unique: true, required: true},
    nameLower:  {type: String, unique: true, required: true}
});

var roomSchema = mongoose.Schema({
    name:       {type: String, unique: true, required: true},
    open:       {type: Boolean, required: true},
    audience:   {type: Array, required: true},
    djs:        {type: Array}
});

var User = mongoose.model('User', userSchema);
var Room = mongoose.model('Room', roomSchema);


var db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function() {
    console.log('connected to db')
    //mostly for testing
    //manually create modles here

    var r1 = new Room({
        name: 'Nefarious Incantations of Mindrot',
        open: true,
        audience: [
            {googleId: '90923324', name: 'guryGURY', nameLower: 'gurygury'}
        ],
        djs: [
            {googleId: '120213213', name: 'o01226', nameLower: 'o01226'}
        ]
    });
    var r2 = new Room({
        name: 'Negligent Torture',
        open: true,
        audience: [
            {googleId: '90923324', name: 'guryGURY', nameLower: 'gurygury'}
        ],
        djs: [
            {googleId: '120213213', name: 'o01226', nameLower: 'o01226'}
        ]
    });
    var r3 = new Room({
        name: 'FATSS',
        open: true,
        audience: [
            {googleId: '90923324', name: 'guryGURY', nameLower: 'gurygury'}
        ],
        djs: [
            {googleId: '120213213', name: 'o01226', nameLower: 'o01226'}
        ]
    });

    r1.save(function(err) {});
    r2.save(function(err) {});
    r3.save(function(err) {});
});

/*
    mongo terminal
    http://www.tutorialspoint.com/mongodb/mongodb_drop_collection.htm
*/

//api
//video search
//video sync
//chat

