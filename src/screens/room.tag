<room>
    <section>
        <div class="sidebar">
            <input class="search" onkeyup={searchChanged} type="text" placeholder="search music" value={query}>

            <!-- search results -->
            <div class="search-results {searching?'searching':''}">
                <p class="search-close" onclick={closeSearch}>Back to room</p>
                <p class="results-header"><span class="query">{query}</span> search results</p>
                <ul class="results-holder">
                    <li class="result" each={searchResults}>
                        <img src="{snippet.thumbnails.medium.url}" width="100%" alt="" />
                        <p class="title">{snippet.title}</p>
                        <p hide={added} class="add" onclick={addToPlaylist}>+ Add to playlist</p>
                        <p show={added} class="added">In playlist!</p>
                    </li>
                </ul>
            </div>

            <!-- playlists -->
            <div class="container {selectingList?'list-open':''}">
                <div show={currentList && !creatingPlaylist} class="playlists">
                    <div class="dropdown">
                        <div class="selected" onclick={openPlaylists}>
                            <p>{currentList.name}</p>
                        </div>
                        <div class="options">
                            <ul>
                                <li onclick={closePlaylists}>Select a playlist</li>
                                <li each={playlists} onclick={selectPlaylist}>{name}</li>
                            </ul>
                            <div class="new-playlist">
                                <button onclick={togglePlaylistForm}>+ Create new playlist</button>
                            </div>
                        </div>
                    </div>
                    <div class="track-holder">
                        <ul class="tracks">
                            <li each={currentList.tracks}><span class="num">{index}.</span> {title}</li>
                        </ul>
                    </div>
                </div>

                <div show={creatingPlaylist} class="create-playlist {postingPlaylist?'posting':''}">
                    <p class="name-label">Give your new playlist a name:</p>
                    <input class="playlist-name" type="text" placeholder="playlist name" onkeyup={playlistNameChange} value={newPlaylistName}>

                    <p class="cancel-btn" onclick={togglePlaylistForm}>Cancel</p>
                    <button class="create-btn" type="button" onclick={createPlaylist}>Create</button>
                </div>

                <p class="user"><span class="name">{user.name}</span> - <span class="leave" onclick={leaveRoom}>Leave room</span></p>
            </div>
        </div>

        <!-- chat -->
        <div class="chat">
            <p class="room-name">{room.name}</p>
            <div class="convo">
                <p class="message"><span class="user">wzrdfght:</span> <span class="text"> Hi everybody!</span></p>
                <p class="message"><span class="user">ViLLaiN:</span> <span class="text"> All right yes that is possible but unlikey as we agreed right?</span></p>
            </div>
            <input class="chat-box" type="text" placeholder="chat">
        </div>

        <!-- stage -->
        <div class="stage">
            <div class="video-holder">
                <div class="video">
                    <img src="assets/img/gorillaz.jpg" alt="" width="100%" />
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
                    <img class={full: img} src="{img || 'assets/img/avatar.png'}" width="42" height="42" alt="" />
                    <p class="avatar-name">{name}</p>
                </div>
            </div>
            <h2 class="logo">hydra.fm</h2>
        </div>
    </section>

    <script>
        var self = this
        self.creatingPlaylist = false

        RiotControl.on('render_room', function(user, room) {
            self.user = user
            self.room = room
            //if user has playlists
            if(self.user.playlists.length) {
                var listUrl = '/api/playlists/'
                listUrl += self.user.playlists.join(',')

                //get users playlists
                U.ajax('GET', listUrl, function(lists) {
                    self.setCurrentPlaylist(lists[0])
                    self.playlists = lists
                    self.update();
                })
            } else {
                self.update()
            }

            //load audience avatars
            for(var i=0, l=room.audience.length; i<l; i++) {
                getGoogleAvatar(i, room.audience[i].googleId, function(index, img) {
                    room.audience[index].img = img
                    self.update()
                })
            }

            //load dj avatars
            for(var j=0, l=room.djs.length; j<l; j++) {
                getGoogleAvatar(j, room.djs[j].googleId, function(index, img) {
                    room.djs[index].img = img
                    self.update()
                })
            }
        })
    
        //select a playlist 
        selectPlaylist(e) {
            self.setCurrentPlaylist(e.item)
            self.selectingList = false
        }

        //open playlist dropdown
        openPlaylists(e) {
            var listUrl = '/api/playlists/'
            listUrl += self.user.playlists.join(',')

            //get users playlists
            U.ajax('GET', listUrl, function(lists) {
                self.playlists = lists
                self.selectingList = true
                self.update();
            })
        }

        //close playlist dropdown
        closePlaylists(e) {
            self.selectingList = false
        }

        //toggle create playlist form
        togglePlaylistForm(e) {
            self.creatingPlaylist = !self.creatingPlaylist
        }

        //new playlist name
        playlistNameChange(e) {
            self.newPlaylistName = e.target.value
        }

        //create the new playlist
        createPlaylist(e) {
            self.postingPlaylist = true
            //post a new playlist
            U.ajax('POST', '/api/playlists', function(data) {
                self.user = data.user
                self.setCurrentPlaylist(data.playlist)
                self.playlists = data.playlists
                self.creatingPlaylist = false
                self.postingPlaylist = false
                self.update()
            }, {
                creatorId: self.user.googleId,
                creatorName: self.user.name,
                name: self.newPlaylistName,
                privateList: false,
                tracks: []
            })
        }

        //loop through current playlist tracks and assign index
        setCurrentPlaylist(list) {
            for(var i=0, l=list.tracks.length; i<l; i++) {
                list.tracks[i].index = i + 1
            }
            self.currentList = list
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

                    var tl = self.currentList.tracks.length
                    var rl = data.items.length

                    //check if any results are already in playlist
                    for(var i=0; i<tl; i++) {
                        for(var j=0; j<rl; j++) {
                            //if video id matches track _id set added to true
                            if(self.currentList.tracks[i]._id == data.items[j].id.videoId) {
                                console.log('found a match')
                                data.items[j].added = true
                            }
                        }
                    }
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
            var trackData = {
                track: {
                    _id: e.item.id.videoId,
                    title: e.item.snippet.title
                },
                playlistId: self.currentList._id
            }

            e.item.added = true

            U.ajax('POST', '/api/addtrack', function(updatedPlylist) {
                self.setCurrentPlaylist(updatedPlylist)
                self.update()
            }, trackData)
        }

        leaveRoom(e) {
            RiotControl.trigger('room.left_room', self.room)
        }
    </script>
</room>