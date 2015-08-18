
//SERVER
var express = require('express');
var bparser = require('body-parser');
var request = require('request');
var socketIo = require('socket.io');

var app = express();
var server = app.listen(8000, createServer);

var io = socketIo(server);
var socket;



//on socket connect
io.on('connection', function (sock) {
    //save socket instance
    socket = sock;

    socket.on('chat_message', function(data) {
        console.log(data.message);
        socket.emit('new_chat_message', data)
    });
});

function createServer() {
    var host = server.address().address;
    var port = server.address().port;

    app.set('views', './views')
    app.set('view engine', 'jade');
    
    app.use(bparser.urlencoded({extended: true}));
    app.use(bparser.json());
    app.use(express.static('./dist'));


    //USER STUFF

    //sign in
    app.post('/signin', function (req, res) {
        //verify token is valid
        var url = 'https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=' + req.body.token;
        request(url, function (error, response, body) {
            if (!error && response.statusCode == 200) {
                var parsed = JSON.parse(body);
                //verify client id matches
                if(parsed.aud == '325125235792-vosk7ah47madtojr3lemn49i631n3n1h.apps.googleusercontent.com') {
                    //send back unique google id
                    res.send({googleId: parsed.sub});
                } else {
                    res.send({googleId: null});
                }
            }
        });
    });



    //API

    //get all rooms
    app.get('/api/rooms', function (req, res) {
        Room.find(function (err, rooms) {
            if (!err) {
                return res.send(rooms);
            } else {
                return console.log(err);
            }
        });
    });

    //get a room
    app.get('/api/rooms/:id', function (req, res) {
        Room.findOne({_id: req.params.id}, function (err, room) {
            room = room || {_id: null};
            if (!err) {
                return res.send(room);
            } else {
                return console.log(err);
            }
        });
    });

    //checks if a room name already exists
    app.get('/api/checkroomname/:name', function (req, res) {
        var ln = decodeURIComponent(req.params.name).toLowerCase();
        Room.findOne({nameLower: ln}, function (err, room) {
            room = room || {name: null};
            if (!err) {
                return res.send(room);
            } else {
                return console.log(err);
            }
        });
    });

    //create a room
    app.post('/api/rooms', function (req, res) {
        var room = new Room({
            name:           req.body.name.trim(),
            nameLower:      req.body.name.trim().toLowerCase(),
            privateRoom:    req.body.privateRoom,
            audience:       req.body.audience,
            djs:            req.body.djs
        });
        
        room.save(function (err) {
            if (!err) {
                console.log('room created: ' + room.name);
                return res.send(room);
            } else {
                return console.log(err);
            }
        });
    });

    app.put('/api/roomtrack/:id', function (req, res) {
        Room.findById(req.params.id, function (err, room) {
            room.currentTrack = req.body.track;

            room.save(function(err) {
                if(!err) {
                    console.log('updated room track');
                    res.send(room);
                    socket.emit('room_track_changed', room);
                } else {
                    console.log(err);
                }
            })
        });
    });

    //update a rooms users
    app.put('/api/roomusers/:id', function (req, res) {
        Room.findById(req.params.id, function (err, room) {
            //update room audience
            if(req.body.audience) {
                room.audience = req.body.audience;
            }

            //update room djs
            if(req.body.djs) {
                //set new djs
                room.djs = req.body.djs;
                
                if(room.djs.length === 0) {
                    //if no djs are playing
                    room.currentDj = undefined;
                    //also clear the current track
                    room.currentTrack = undefined;
                } else if(room.djs.length === 1) {
                    //if there is only 1 dj, make them current
                    room.currentDj = {spot: 0, _id: room.djs[0]._id};
                } else {
                    //when a dj quits, keep current dj value the same
                    if(room.currentDj.spot > room.djs.length - 1) {
                        //unless the last dj quit, then go back to first
                        room.currentDj = {spot: 0, _id: room.djs[0]._id};
                    }
                }
            }

            if(room.audience.length + room.djs.length == 0) {
                //if room is now empty, delete it
                room.remove(function (err) {
                    if (!err) {
                        console.log('removed');
                        return res.send({removed: true});
                    } else {
                        console.log(err);
                    }
                });
            } else {
                //save room with updated users
                room.save(function (err) {
                    if (!err) {
                        res.send(room);
                        socket.emit('room_users_changed', room);
                    } else {
                        console.log(err);
                    }
                });
            }
        });
    });

    //get a user by googleid
    app.get('/api/users/:googleid', function (req, res) {
        User.findOne({googleId: req.params.googleid}, function (err, user) {
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
        User.findOne({nameLower: ln}, function (err, user) {
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

        //create default playlist
        var playlist = new Playlist({
            creatorId:      req.body.googleId,
            creatorName:    req.body.name.trim(),
            name:           'Default Playlist!',
            privateList:    false,
            tracks:         []
        });

        //save default playlist
        playlist.save(function(err) {
            //create new user
            var user = new User({
                googleId:   req.body.googleId,
                name:       req.body.name.trim(),
                nameLower:  req.body.name.trim().toLowerCase(),
                playlists:  [playlist._id]
            });

            //save user
            user.save(function (err) {
                if (!err) {
                    console.log('user created: ' + user.name);
                    return res.send(user);
                } else {
                  return console.log(err);
                }
            });
        });
    });


    //get a users playlists
    app.get('/api/playlists/:playlists', function (req, res) {
        getUserPlaylists(req.params.playlists, function(playlists) {
            return res.send(playlists);
        });
    });

    //post a new playlist
    app.post('/api/playlists', function (req, res) {

        //create new playlist
        var playlist = new Playlist({
            creatorId:      req.body.creatorId,
            creatorName:    req.body.creatorName,
            name:           req.body.name.trim(),
            privateList:    false,
            tracks:         []
        });

        //save user
        playlist.save(function (err) {
            if (!err) {
                console.log('playlist created: ' + playlist.name);

                //get the current user
                User.findOne({googleId: req.body.creatorId}, function (err, user) {
                    //add playlist to user
                    user.playlists.push(playlist._id);

                    //save playlists on user
                    user.save(function (err) {
                        if(!err) {
                            //get new playlists
                            getUserPlaylists(user.playlists.join(','), function(playlists) {

                                //console.log(playlists);
                                var response = {
                                    user: user,
                                    playlist: playlist,
                                    playlists: playlists
                                };
                                return res.send(response);
                            });
                        } else {
                            console.log(err);
                        }
                    });
                });
            } else {
              return console.log(err);
            }
        });
    });

    //add a track to a playlist
    app.post('/api/addtrack', function (req, res) {
        Playlist.findOne({_id: req.body.playlistId}, function(err, playlist) {
            if(!err) {
                playlist.tracks.push(req.body.track);
                //save playlist
                playlist.save(function (err) {
                    return res.send(playlist);
                });
            } else {
                console.log(err);
            }
        });
    });

    //remove a track from a playlist
    app.post('/api/removetrack', function (req, res) {
        Playlist.findOne({_id: req.body.playlistId}, function(err, playlist) {
            if(!err) {
                //remove track from playlist
                for(var i=0, l=playlist.tracks.length; i<l; i++) {
                    if(playlist.tracks[i]._id == req.body.trackId) {
                        playlist.tracks.splice(i, 1);
                        break;
                    }
                }
                //save playlist
                playlist.save(function (err) {
                    return res.send(playlist);
                });
            } else {
                console.log(err);
            }
        });
    });

    //when a track finishes playing, move it to last in list
    //when a user changes the order of their playlist
    app.post('/api/playlistorder', function (req, res) {
        Playlist.findOne({_id: req.body.playlistId}, function(err, playlist) {
            if(!err) {
                //delete the track indexes
                for(var i=0, l=req.body.tracks.length; i<l; i++) {
                    delete req.body.tracks[i].index;
                }
                //update track order
                playlist.tracks = req.body.tracks;

                //save playlist
                playlist.save(function (err) {
                    return res.send(playlist);
                });
            } else {
                console.log(err);
            }
        });
    });

    console.log('Example app listening at http://%s:%s', host, port);
}

function getUserPlaylists(listIds, callback) {
    var lists = listIds.split(',');
    Playlist.find({
        '_id': { $in: lists}
    }, function(err, playlists) {
        callback(playlists);
    });
}


//ROUTES
app.get('/', function (req, res) {
    res.render('index');
});

app.get('/oauth2callback', function(req, res) {
    res.render('oauth2callback');
})


//DATABASE
var mongoose = require('mongoose');
var options = { server: { socketOptions: { keepAlive: 1, connectTimeoutMS: 30000 } }, 
                replset: { socketOptions: { keepAlive: 1, connectTimeoutMS : 30000 } } };

//set up database connection
mongoose.connect('mongodb://localhost/hydra', options); //DEV

//define Users
var userSchema = mongoose.Schema({
    googleId:   {type: String, unique: true, required: true},
    name:       {type: String, unique: true, required: true},
    nameLower:  {type: String, unique: true, required: true},
    playlists:  {type: Array} //holds ids of playlists
});

//define Playlists
var playlistSchema = mongoose.Schema({
    creatorId:      {type: String, required: true},
    creatorName:    {type: String, required: true},
    name:           {type: String, unique: true, required: true},
    privateList:    {type: Boolean, required: true},
    tracks:         {type: Array} //holds {id: youtube_video_id, name: youtube_video_name}
});

//define Rooms
var roomSchema = mongoose.Schema({
    name:           {type: String, unique: true, required: true},
    nameLower:      {type: String, unique: true, required: true},
    privateRoom:    {type: Boolean, required: true},
    audience:       {type: Array}, //holds User models
    djs:            {type: Array}, //holds User models
    currentDj:      {type: Object}, //{spot: array-index, _id: user-id}
    currentTrack:   {type: Object} //youtube video id and name
});

//init models
var User = mongoose.model('User', userSchema);
var Playlist = mongoose.model('Playlist', playlistSchema);
var Room = mongoose.model('Room', roomSchema);

//create database connection
var db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function() {
    console.log('connected to db');
    //mostly for testing
    //manually create models here

    var u1 = new User({
        googleId: '1232423434',
        name: 'TIM the !',
        nameLower: 'tim the !',
        playlists: []
    });
    u1.save(function(err) {console.log('created')});


    var r1 = new Room({
        name: 'Mindrot',
        nameLower: 'mindrot',
        privateRoom: false,
        audience: [
            {googleId: '90923324', name: 'guryGURY', nameLower: 'gurygury'}
        ],
        djs: [],
        currentDj: undefined
    });
    var r2 = new Room({
        name: 'Torture',
        nameLower: 'torture',
        privateRoom: false,
        audience: [
            {googleId: '90923324', name: 'guryGURY', nameLower: 'gurygury'}
        ],
        djs: [],
        currentDj: undefined
    });
    var r3 = new Room({
        name: 'FATSS',
        nameLower: 'fatss',
        privateRoom: false,
        audience: [
            {googleId: '90923324', name: 'guryGURY', nameLower: 'gurygury'}
        ],
        djs: [],
        currentDj: undefined
    });
    r1.save(function(err) {console.log('created')});
    r2.save(function(err) {console.log('created')});
    r3.save(function(err) {console.log('created')});
});


