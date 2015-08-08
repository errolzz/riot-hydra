<room>
    <p>room</p>
    <h1>{room.name}</h1>

    <script>
        var self = this;
        RiotControl.on('render_room', function(room) {
            self.room = room.id
            console.log(room)
            console.log(room.id.name)
        });
    </script>
</room>