function AppStore() {
    riot.observable(this)

    var self = this;
    self.rooms = API.rooms
    self.user = undefined;

    //LOGIN
    self.on('login.enter', function(user) {
        self.user = user
        self.trigger('screen_changed', 'lobby');
        self.trigger('rooms_loaded', self.rooms);
    });


    //LOBBY
    self.on('lobby.enter_room', function(room) {
        //set url to '/room/' + room
        //for now
        self.trigger('screen_changed', 'room');
        self.trigger('render_room', room);
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
        //user left room
        self.trigger('screen_changed', 'lobby');
        
        //remove user from room
        U.removeOne('id', self.user.id, room.audience);
        U.removeOne('id', self.user.id, room.djs);

        //check if room is empty
        if(room.audience.length + room.djs.length == 0) {
            //if empty, delete room
            U.removeOne('id', room.id, self.rooms)
        }

        //update lobby
        self.trigger('rooms_loaded', self.rooms);
    });
}

var U = {};
U.removeOne = function(prop, value, list) {
    for(var i=0, l=list.length; i<l; i++) {
        if(list[i][prop] == value) {
            return list.splice(i, 1);
        }
    }
}