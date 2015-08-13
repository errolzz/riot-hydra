<room>
    <section>
        <div class="sidebar">
            <input class="search" onkeyup={searchChanged} type="text" placeholder="search music" value={query}>

            <div class="search-results {searching?'searching':''}">
                <p class="search-close" onclick={closeSearch}>Back to room</p>
                <p class="results-header"><span class="query">{query}</span> search results</p>
                <ul class="results-holder">
                    <li class="result" each={searchResults}>
                        <img src="{snippet.thumbnails.medium.url}" width="100%" alt="" />
                        <p class="title">{snippet.title}</p>
                        <p class="add" onclick={addToPlaylist}>+ Add to playlist</p>
                    </li>
                </ul>
            </div>

            <div class="container {selectingList?'list-open':''}">
                <div class="dropdown">
                    <div class="selected" onclick={openPlaylists}>
                        <p>{currentList.snippet.title}</p>
                    </div>
                    <div class="options">
                        <ul>
                            <li onclick={closePlaylists}>Select a playlist</li>
                            <li each={playlists}>{snippet.title}</li>
                            <!-- <li class="new-list">+ Create New List</li> -->
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

            //get users playlists
            var listUrl = 'https://www.googleapis.com/youtube/v3/playlists';
            listUrl += '?mine=true&part=snippet&access_token=' + U.getCookie('access_token');

            U.ajax('GET', listUrl, function(data) {
                self.currentList = data.items[0]
                self.playlists = data.items
                self.update();
            }, null, function(error) {
                //if token has expired
                
            })

            //auto select first playlist

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

        openPlaylists(e) {
            self.selectingList = true
        }

        closePlaylists(e) {
            self.selectingList = false
        }

        searchChanged(e) {
            if(e.keyCode == 27) {
                //hit escape key, kill search
                self.closeSearch()
            } else {
                //set up query to be searched
                self.query = e.target.value

                if(self.query.trim().length > 0) {
                    //if value in field, call search
                    self.searching = true
                    self.search()
                } else {
                    //if no value, close search
                    self.closeSearch()
                }
            }
        }

        search() {
            //set up query
            var q = 'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video'
            q += '&videoCategoryId=10&maxResults=20&key=AIzaSyBRzzVaMuLFIKLA2MAcbmEWVbx5JWXmxSE&q='
            q += encodeURIComponent(self.query)

            //set search on delay timer
            try {
                window.clearTimeout(searchTimer)
            } catch(e) {
                //no time to clear
            }

            searchTimer = window.setTimeout(function() {
                U.ajax('GET', q, function(data) {
                    self.searchResults = data.items
                    self.update()
                })
            }, 666)
        }

        closeSearch(e) {
            self.query = ''
            self.searching = false
            window.clearTimeout(searchTimer)
            self.searchResults = []
        }

        addToPlaylist(e) {
            console.log(e.item);
            //add to self.currentList
        }

        leaveRoom(e) {
            RiotControl.trigger('room.left_room', self.room)
        }
    </script>
</room>