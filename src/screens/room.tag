<room>
    <div class="sidebar">
        <input type="text" placeholder="search music">
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
            <li>Song One</li>
            <li>Track of the Two</li>
        </ul>
        <p class="leave">Leave room</p>
    </div>
    <div class="chat">
        <p>{room.name}</p>
        <div class="convo">
            <p><span class="user">wzrdfght:</span> <span class="message"> Hi everybody!</span></p>
        </div>
        <input type="text" placeholder="chat">
    </div>
    <div class="stage">
        <div class="video-holder">
            <div class="djs">
                <div class="avatar"></div>
                <div class="avatar"></div>
                <div class="avatar"></div>
                <div class="avatar"></div>
                <div class="be-dj"></div>
            </div>
            <div class="overlay">
                <p class="title">Song Title</p>
                <p class="like-song">+ Apprecieate Track +</p>
            </div>
        </div>
        <div class="audience">
            <ul>
                <li>
                    <div class="avatar"></div>
                    <p class="avatar-name">DJ Fonky Family</p>
                </li>
            </ul>
        </div>
        <div class="logo">hydra.fm</div>
    </div>

    <script>
        var self = this;
        RiotControl.on('render_room', function(room) {
            console.log('rendering')
            self.room = room
            self.update()
        });
    </script>
</room>