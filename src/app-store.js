

function AppStore() {
    riot.observable(this)

    var self = this;
    self.user = undefined;

    self.signedIn = function(profile) {
        //check if user has been here before

        U.ajax('GET', '/api/users/' + profile.googleId, function(data) {
            //if no user was found
            if(!data.googleId) {
                //new user temp object
                var firstname = profile.getName().substring(0, profile.getName().indexOf(' '));
                var u = {
                    googleId: profile.googleId,
                    name: '',
                    img: profile.getImageUrl()
                };
                self.trigger('new_user', {user: u, firstname: firstname});
            } else {
                self.user = data;
                //save the users avatar img, it's not saved in the db
                self.user.img = profile.getImageUrl();
                
                var url = String(window.location.hash).substring(1);
                
                if(url.length == 0 || url == '#') {
                    riot.route('lobby');
                } else {
                    riot.route(url);
                }
            }

            document.getElementById('site').style.display = 'block';
        });
    }

    //APP / ROUTER
    self.on('app.app_mounted', function() {
        riot.route(function(p1, p2, p3) {

            if(p1 == 'lobby') {
                self.trigger('screen_changed', 'lobby');
                //GET rooms here
                U.ajax('GET', '/api/rooms', function(rooms) {
                    self.trigger('rooms_loaded', self.user, rooms);
                });

            } else if(p1 == 'room') {
                U.ajax('GET', '/api/rooms', function(rooms) {
                    var room = U.getOne('_id', p2, rooms);
                    if(room) {
                        self.trigger('screen_changed', 'room');
                        self.trigger('render_room', self.user, room);
                    } else {
                        riot.route('lobby');
                    }
                });
            }
        });
    })


    //LOGIN
    self.on('login.create_user', function(user) {
        //post new user
        U.ajax('POST', '/api/users', function(data) {
            if(data.googleId) {
                //update local user
                self.user = user;
                riot.route('lobby');
            }
        }, user);
    });


    //LOBBY
    self.on('lobby.enter_room', function(room) {
        //update room in db with new audience and djs
        U.ajax('PUT', '/api/roomusers/' + room._id, function(addedUserToRoom) {
            //user left room
            riot.route('room/' + room._id);
        }, {audience: room.audience});
    });

    //when a new room is created
    self.on('lobby.create_room', function(roomData) {
        var newRoom = {
            name: roomData.name,
            privateRoom: roomData.privateRoom,
            audience: [self.user],
            djs: []
        };
        U.ajax('POST', '/api/rooms', function(room) {
            self.trigger('room_added', room);
        }, newRoom);
    });


    //ROOM
    self.on('room.left_room', function(room) {
        //remove user from local room object
        U.removeOne('_id', self.user._id, room.audience);
        U.removeOne('_id', self.user._id, room.djs);
        
        //update room in db with new audience and djs
        U.ajax('PUT', '/api/roomusers/' + room._id, function(removedUserFromRoom) {
            //user left room
            riot.route('lobby');
        }, {audience: room.audience, djs: room.djs});
    });
}


//units
var U = {};
U.getOne = function(prop, value, list) {
    for(var i=0, l=list.length; i<l; i++) {
        if(list[i][prop] == value) {
            return list[i];
        }
    }
}
U.removeOne = function(prop, value, list) {
    for(var i=0, l=list.length; i<l; i++) {
        if(list[i][prop] == value) {
            return list.splice(i, 1);
        }
    }
}
U.ajax = function(type, url, success, data, error) {
    var request = new XMLHttpRequest();
    request.open(type, url, true);
    request.onload = function() {
        if (request.status >= 200 && request.status < 400) {
            var data = JSON.parse(request.responseText);
            try {success(data);} catch(e) {}
        } else {
            console.log(request)
            try {error(request);} catch(e) {}
        }
    };
    request.onerror = function() {
        console.log(request)
        try {error(request);} catch(e) {}
    };
    if(type == 'POST' || type == 'PUT') {
        request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
        request.send(JSON.stringify(data));
    } else {
        request.send();
    }
}


//google sign in
function onGoogleSignIn(googleUser) {
    var profile = googleUser.getBasicProfile();
    var id_token = googleUser.getAuthResponse().id_token;

    document.getElementById('site').style.display = 'none';

    //validate the id token
    U.ajax('POST', '/signin', function(data) {
        if(data.googleId) {
            //all set, save token
            profile.googleId = data.googleId;
            appStore.signedIn(profile);
        } else {
            //no good, sign out
            var auth2 = gapi.auth2.getAuthInstance();
            auth2.signOut();
        }
    }, {token: id_token});
}





