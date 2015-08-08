function AppStore() {
    riot.observable(this)

    var self = this;
    self.rooms = API.rooms;

    //LOGIN
    self.on('login.enter', function() {
        self.trigger('screen_changed', 'lobby');
    });

    //LOBBY

    //lobby init
    self.on('lobby.init', function() {
        self.trigger('rooms_loaded', self.rooms);
    });

    //when a new room is created
    self.on('lobby.create_room', function(roomData) {
        var room = {
            id: self.rooms.length,
            name: roomData.name,
            open: roomData.open
        };
        self.rooms.push(room);
        self.trigger('room_added', self.items);
    });


    //ROOM

    //user left room
    self.on('room.left_room', function(user, roomId) {
        //remove user from room
        //check if room is empty
        //if empty, delete room
    });
}