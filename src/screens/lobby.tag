<lobby>
    <section class={create: showCreate}>
        <div class="sidebar">
            <h2>hydra.fm</h2>
            <p>Join a listening room or create your own.</p>
            <p class="user"><span class="name">{user.name}</span> - <span class="logout" onclick={signOut}>Log out</span></p>
        </div>
        <div class="room-list">
            <div class="lobby-control">
                <input type="text" placeholder="search rooms" onkeyup={searchChange} value={roomSearch}>
                <p class="or">or</p>
                <p class="create-link" onclick={openCreate}>+ Create new room</p>
            </div>
            <div class="rooms">
                <ul>
                    <li each={rooms} hide={hide}>
                        <div class="room-label" onclick={parent.roomClick}>
                            <p class="name">{name}</p>
                            <p class="count">({djs.length + audience.length} Listeners)</p>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
        <div class="create-room">
            <p class="name-label">Choose a name for your room:</p>
            <input class="room-name" type="text" placeholder="room name" onkeyup={nameChange} value={newRoomName}>
            <p class="error" show={error}>{error}</p>

            <p class="private-label">Make it a private room?</p>
            <div class="private">
                <input id="private-id" type="checkbox" value="private" onclick={togglePrivateRoom}> 
                <label for="private-id">yes</label>
            </div>

            <p class="cancel-btn" onclick={closeCreate}>Cancel</p>
            <button class="create-btn" type="button" onclick={createRoom}>Create</button>
        </div>
    </section>

    <script>
        var self = this
        self.newRoomName = ''
        self.privateRoom = false 

        self.on('mount', function() {
            // Trigger init event when component is mounted to page.
            // Any store could respond to this.
            RiotControl.trigger('lobby.init')
            self.roomSearch = ''
            self.showCreate = false
        })

        nameChange(e) {
            self.newRoomName = e.target.value
        }

        togglePrivateRoom(e) {
            self.privateRoom = !self.privateRoom
        }

        openCreate(e) {
            self.showCreate = true
        }

        closeCreate(e) {
            self.showCreate = false
        }

        searchChange(e) {
            self.roomSearch = e.target.value
            var s = self.roomSearch.trim().toLowerCase()

            for(var i=0, l=self.rooms.length; i<l; i++) {
                if(s.length) {
                    if(self.rooms[i].nameLower.indexOf(s) < 0) {
                        //hide room
                        self.rooms[i].hide = true
                    } else {
                        self.rooms[i].hide = false
                    }
                } else {
                    self.rooms[i].hide = false
                }
            }
        }

        createRoom(e) {
            if(self.newRoomName.trim().length > 3) {
                //check if room name exists
                U.ajax('GET', '/api/checkroomname/' + encodeURIComponent(self.newRoomName.trim()), function(data) {
                    if(!data.name) {
                        //name is valid and available, create user
                        RiotControl.trigger('lobby.create_room', {name: self.newRoomName, privateRoom: self.privateRoom})
                        self.showCreate = false
                        self.newRoomName = ''
                    } else {
                        //name is not available
                        self.error = 'That room name is already in use'
                        self.update();
                    }
                });
            } else {
                self.error = 'Room names must be at least 4 characters long'
                self.update();
            }
        }

        //room list
        RiotControl.on('rooms_loaded', function(user, rooms) {
            self.user = user
            self.rooms = rooms
            self.update()
        })

        //room clicked, enter room
        roomClick(e) {
            self.roomSearch = ''
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