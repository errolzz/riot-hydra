

function AppStore() {
    riot.observable(this)

    var self = this;
    self.rooms = API.rooms;
    self.users = API.users;
    self.user = undefined;

    self.signedIn = function(profile) {
        //check if user has been here before
        U.ajax('GET', '/api/users/' + profile.googleId, function(data) {
            //if no user was found
            if(data.googleId == 'none') {
                //new user temp object
                var firstname = profile.getName().substring(0, profile.getName().indexOf(' '));
                var u = {
                    googleId: profile.googleId,
                    name: '',
                    img: profile.getImageUrl()
                };
                self.trigger('new_user', {user: u, firstname: firstname});

                //make sure they are on the login page if not logged in
                window.location = '/';
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
        riot.route(function(collection, id, action) {
            if(collection == 'lobby') {
                self.trigger('screen_changed', 'lobby');
                self.trigger('rooms_loaded', self.user, self.rooms);
            } else if(collection == 'room') {
                var room = U.getOne('id', id, self.rooms);
                self.trigger('screen_changed', 'room');
                self.trigger('render_room', self.user, room);
            }
        });
    })


    //LOGIN
    self.on('login.createNewUser', function(user) {
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
        riot.route('room/' + room.id);
    });

    //when a new room is created
    self.on('lobby.create_room', function(roomData) {
        var room = {
            id: self.rooms.length,
            name: roomData.name,
            open: roomData.open,
            audience: [self.user],
            djs: []
        };
        self.rooms.push(room);
        self.trigger('room_added', room);
    });


    //ROOM
    self.on('room.left_room', function(room) {
        //remove user from room
        U.removeOne('id', self.user.id, room.audience);
        U.removeOne('id', self.user.id, room.djs);

        //check if room is empty
        if(room.audience.length + room.djs.length == 0) {
            //if empty, delete room
            U.removeOne('id', room.id, self.rooms);
        }

        //user left room
        riot.route('lobby')
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
    if(type == 'POST') {
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





