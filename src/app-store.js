

function AppStore() {
    riot.observable(this)

    var self = this;
    self.rooms = API.rooms;
    self.users = API.users;
    self.user = undefined;

    self.signedIn = function(profile) {
        //check if user has been here before
        self.user = U.getOne('id', profile.token, self.users);

        if(!self.user) {
            //new user
            var firstname = profile.getName().substring(0, profile.getName().indexOf(' '));
            var u = {
                id: profile.token,
                name: '',
                email: profile.getEmail(),
                img: profile.getImageUrl()
            };
            self.trigger('new_user', {user: u, firstname: firstname});
        } else {
            //return user
            riot.route('lobby');
        }
    }

    //APP / ROUTER
    self.on('app.app_mounted', function() {
        riot.route(function(collection, id, action) {
            if(collection == 'lobby') {
                self.trigger('screen_changed', 'lobby');
                self.trigger('rooms_loaded', self.rooms);
            } else if(collection == 'room') {
                var room = U.getOne('id', id, self.rooms);
                self.trigger('screen_changed', 'room');
                self.trigger('render_room', room);
            }
        });
        var url = String(window.location.hash).substring(1);
        riot.route(url);
    })


    //LOGIN
    self.on('login.createNewUser', function(user) {
        self.user = user;
        self.users.push(user);
        riot.route('lobby');
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


//google sign in
function onGoogleSignIn(googleUser) {
    var profile = googleUser.getBasicProfile();
    var id_token = googleUser.getAuthResponse().id_token;

    //validate the id token
    var xhrInfo = new XMLHttpRequest();
    xhrInfo.open('GET','https://www.googleapis.com/oauth2/v3/tokeninfo?id_token='+id_token);
    xhrInfo.onload = function() {
        var res = JSON.parse(xhrInfo.responseText);
        if(res.aud == '325125235792-vosk7ah47madtojr3lemn49i631n3n1h.apps.googleusercontent.com') {
            //all set, save token
            profile.token = id_token;
            appStore.signedIn(profile);
        } else {
            //no good, sign out
            var auth2 = gapi.auth2.getAuthInstance();
            auth2.signOut();
        }
    }
    xhrInfo.send();
}





