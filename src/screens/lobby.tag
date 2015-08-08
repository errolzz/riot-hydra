<lobby>
    <div class="sidebar">
        <h2>hydra.fm</h2>
        <p>Join a listening room or create your own.</p>
    </div>
    <div class="roomlist">
        <div class="create-new">
            <input type="text" placeholder="search rooms">
            <p>+ Create new room</p>
        </div>
        <ul>
            <li each={ rooms }>
                <div class="room-label" onclick={roomClick}>
                    <p class="name">{name}</p>
                    <p class="count">(33 Listeners)</p>
                </div>
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
        self.rooms = API.rooms;

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
                RiotControl.trigger('lobby.create_room', {name: self.text, open: true})
                self.text = self.input.value = ''
            }
        }

        roomClick(e) {
            RiotControl.trigger('lobby.enter_room', {id: e.item})
        }

        // Register a listener for store change events.
        RiotControl.on('lobby.create_room', function(items) {
            
        })
    </script>
</lobby>