<lobby>
    <section class={create: showCreate}>
        <div class="sidebar">
            <h2>hydra.fm</h2>
            <p>Join a listening room or create your own.</p>
            <p class="logout" onclick={signOut}>Log out</p>
        </div>
        <div class="room-list">
            <div class="create-new">
                <input type="text" placeholder="search rooms">
                <p onclick={openCreate}>+ Create new room</p>
            </div>
            <ul>
                <li each={ rooms }>
                    <div class="room-label" onclick={parent.roomClick}>
                        <p class="name">{name}</p>
                        <p class="count">(33 Listeners)</p>
                    </div>
                </li>
            </ul>
        </div>
        <div class="create-room">
            <p class="name-label">Choose a name for your room:</p>
            <input class="room-name" type="text" placeholder="room name" onkeyup={nameChange} value={newRoomName}>
            <p class="error" show={error}>{error}</p>

            <p class="private-label">Make it a private room?</p>
            <div class="private"><input type="checkbox" value="private" onclick={togglePriv}> yes</div>

            <p class="cancel-btn" onclick={closeCreate}>Cancel</p>
            <button class="create-btn" type="button" onclick={createRoom}>Create</button>
        </div>
    </section>

    <script>
        var self = this
        self.newRoomName = ''
        self.priv = false 

        self.on('mount', function() {
            // Trigger init event when component is mounted to page.
            // Any store could respond to this.
            RiotControl.trigger('lobby.init')
            self.showCreate = false
        })

        RiotControl.on('update_lobby', function(rooms) {
            
        })

        nameChange(e) {
            self.newRoomName = e.target.value
        }

        togglePriv(e) {
            self.priv = !self.priv
        }

        openCreate(e) {
            self.showCreate = true
        }

        closeCreate(e) {
            self.showCreate = false
        }

        createRoom(e) {
            if(self.newRoomName.length > 3) {
                RiotControl.trigger('lobby.create_room', {name: self.newRoomName, open: self.priv})
                self.showCreate = false
                self.newRoomName = ''
            } else {
                self.error = 'Room names must be at least 4 characters long.'
            }
        }

        //room list
        RiotControl.on('rooms_loaded', function(rooms) {
            self.rooms = rooms
            self.update()
        })

        //room clicked, enter room
        roomClick(e) {
            RiotControl.trigger('lobby.enter_room', e.item)
        }

        //new room was created, enter room
        RiotControl.on('room_added', function(room) {
            RiotControl.trigger('lobby.enter_room', room)
        })

        signOut(e) {
            var auth2 = gapi.auth2.getAuthInstance();
            auth2.signOut();
            window.location = '/';
        }
    </script>
</lobby>