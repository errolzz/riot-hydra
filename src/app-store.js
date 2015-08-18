

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
                    nameLower: '',
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
                //ENTER THE LOBBY
                
                self.trigger('screen_changed', 'lobby');
                //GET rooms here
                U.ajax('GET', '/api/rooms', function(rooms) {
                    self.trigger('rooms_loaded', self.user, rooms);
                });

            } else if(p1 == 'room') {
                //ENTER A ROOM

                //get latest list of rooms
                U.ajax('GET', '/api/rooms/' + p2, function(room) {
                    //if room is valid
                    if(room._id) {
                        //check if user is already in room (refreshed)
                        var isAud = U.getOne('_id', self.user._id, room.audience);
                        var isDj = U.getOne('_id', self.user._id, room.djs)
                        
                        if(!isAud && !isDj) {
                            //add user to room
                            console.log('adding to room')
                            room.audience.push(self.user);    
                        }
                        
                        //update room in db with new audience and djs
                        U.ajax('PUT', '/api/roomusers/' + room._id, function(updatedRoom) {
                            //user joined room
                            self.trigger('screen_changed', 'room');
                            self.trigger('render_room', self.user, updatedRoom);
                        }, {audience: room.audience});
                    } else {
                        //invalid room id, go back to lobby
                        riot.route('lobby');
                    }
                });
            }
        });
    });


    //LOGIN
    self.on('login.create_user', function(user) {
        //post new user
        U.ajax('POST', '/api/users', function(data) {
            if(data.googleId) {
                //update local user
                self.user = data;
                console.log(self.user);
                riot.route('lobby');
            }
        }, user);
    });


    //LOBBY
    self.on('lobby.enter_room', function(room) {
        riot.route('room/' + room._id);
    });

    //when a new room is created
    self.on('lobby.create_room', function(roomData) {
        var newRoom = {
            name: roomData.name,
            privateRoom: roomData.privateRoom,
            audience: [],
            djs: []
        };
        U.ajax('POST', '/api/rooms', function(room) {
            self.trigger('room_added', room);
        }, newRoom);
    });


    //ROOM
    self.on('room.left_room', function() {
        riot.route('lobby');
    });
}


