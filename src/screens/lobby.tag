<lobby>
    <div class="panel">
        <h2>hydra.fm</h2>
        <p>Join a listening room or create a new one.</p>
    </div>
    <div class="rooms">
        <ul>
            <li>
                <div>
                    <input type="text" placeholder="search rooms">
                </div>
                <p>+ Create new room</p>
            </li>
            <li each={ rooms }>
                <p>Room Name</p>
                <button>Join</button>
            </li>
        </ul>
    </div>
    <div class="create-room">
        <input type="text" placeholder="room name" onkeyup={ nameChange }>
        <input type="checkbox" value="private"> Private room?
        <button type="button">Create</button>
    </div>

    <script>
        var self = this
        self.rooms = [];

        self.on('mount', function() {
            // Trigger init event when component is mounted to page.
            // Any store could respond to this.
            RiotControl.trigger('lobby.init')
        })

        nameChange(e) {
            self.newRoomName = e.target.value
        }

        createRoom(e) {
            if(self.newRoomName) {
                RiotControl.trigger('lobby.create_room', { name: self.text, open: true })
                self.text = self.input.value = ''
            }
        }

        // Register a listener for store change events.
        RiotControl.on('lobby.create_room', function(items) {
            
        })
    </script>
</lobby>