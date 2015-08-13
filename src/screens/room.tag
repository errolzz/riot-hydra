<room>
    <section>
        <div class="sidebar">
            <input class="search" type="text" placeholder="search music">
            <div class="container">
                <div class="dropdown">
                    <div class="selected">
                        <p>Gansta 1999 List</p>
                    </div>
                    <div class="options">
                        <ul>
                            <li>List Numba One</li>
                            <li class="new-list">+ Create New List</li>
                        </ul>
                    </div>
                </div>
                <ul class="tracks">
                    <li><span class="num">1.</span> Song One</li>
                    <li><span class="num">2.</span> Track of the Two</li>
                    <li><span class="num">3.</span> Liars</li>
                    <li><span class="num">4.</span> Mission Impossible Soundtrack of the gods</li>
                </ul>
                <p class="user"><span class="name">{user.name}</span> - <span class="leave" onclick={leaveRoom}>Leave room</span></p>
            </div>
        </div>
        <div class="chat">
            <p class="room-name">{room.name}</p>
            <div class="convo">
                <p class="message"><span class="user">wzrdfght:</span> <span class="text"> Hi everybody!</span></p>
                <p class="message"><span class="user">ViLLaiN:</span> <span class="text"> All right yes that is possible but unlikey as we agreed right?</span></p>
            </div>
            <input class="chat-box" type="text" placeholder="chat">
        </div>
        <div class="stage">
            <div class="video-holder">
                <div class="video">
                    <img src="assets/img/chiddy-bang.jpg" alt="" width="100%" />
                </div>
                <div class="djs">
                    <div each={room.djs} class="avatar">
                        <img src="{img || 'assets/img/avatar.png'}" width="42" height="42" alt="" />
                        <p class="avatar-name">{name}</p>
                    </div>
                    <div class="be-dj">
                        <div class="plus">
                            <div class="h"></div>
                            <div class="v"></div>
                        </div>
                    </div>
                </div>
                <div class="overlay">
                    <p class="title">Song Title</p>
                    <p class="like">* Apprecieate Track *</p>
                </div>
            </div>
            <div class="audience">
                <div each={room.audience} class="avatar">
                    <img class={img?'full':''} src="{img || 'assets/img/avatar.png'}" width="42" height="42" alt="" />
                    <p class="avatar-name">{name}</p>
                </div>
            </div>
            <h2 class="logo">hydra.fm</h2>
        </div>
    </section>

    <script>
        var self = this;
        RiotControl.on('render_room', function(user, room) {
            self.user = user
            self.room = room
            self.update()

            //load audience avatars
            for(var i=0, l=room.audience.length; i<l; i++) {
                getGoogleAvatar(i, room.audience[i].googleId, function(index, img) {
                    room.audience[index].img = img
                    self.update()
                })
            }

            //load dj avatars
            for(var i=0, l=room.audience.length; i<l; i++) {
                getGoogleAvatar(i, room.audience[i].googleId, function(index, img) {
                    room.audience[index].img = img
                    self.update()
                })
            }
        })

        leaveRoom(e) {
            RiotControl.trigger('room.left_room', self.room)
        }
    </script>
</room>