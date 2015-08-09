function AppStore() {
    riot.observable(this)

    var self = this;
    self.rooms = API.rooms;

    //LOGIN
    self.on('login.enter', function() {
        self.trigger('screen_changed', 'lobby');
    });


    //LOBBY
    self.on('lobby.init', function() {
        //lobby init
        self.trigger('rooms_loaded', self.rooms);
    });

    self.on('lobby.enter_room', function(room) {
        //set url to '/room/' + room
        //for now
        console.log(room)
        self.trigger('screen_changed', 'room');
        self.trigger('render_room', room);
    });

    //when a new room is created
    self.on('lobby.create_room', function(roomData) {
        var room = {
            id: self.rooms.length,
            name: roomData.name,
            open: roomData.open
        };
        self.rooms.push(room);
        self.trigger('room_added', self.rooms);
    });


    //ROOM
    self.on('room.left_room', function(user, roomId) {
        //user left room
        //remove user from room
        //check if room is empty
        //if empty, delete room
    });
}