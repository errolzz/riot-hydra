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
                    <div id="yt-player">
                        <img src="assets/img/gorillaz.jpg" width="100%" alt="" />
                    </div>
                </div>
                <div class="djs">
                    <div each={room.djs} class="avatar {isPlaying?'playing':''}">
                        <img src="{img || 'assets/img/avatar.png'}" width="42" height="42" alt="" />
                        <p class="avatar-name">{name}</p>
                    </div>
                    <div class="be-dj" show={openDj} onclick={becomeDj}>
                        <button>Start to DJ</button>
                    </div>
                </div>
                <button class="quit-dj" show={userIsDj} onclick={quitDj}>Quit DJ</button>
                <div class="overlay">
                    <p class="title">{room.currentTrack.title}</p>
                    <button class="like">* Apprecieate Track *</button>
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

            var listUrl = '/api/playlists/'
            listUrl += self.user.playlists.join(',')

            //get users playlists
            U.ajax('GET', listUrl, function(lists) {
                self.setCurrentPlaylist(lists[0])
                self.playlists = lists
                self.updateRoom(self.room)
            })

            window.onbeforeunload = function() {
                if(self.userIsDj) {
                    self.quitDj()
                }
            }

            //socket will also emit room_users_changed at this point
        })

        //handle youtube player state changes
        onPlayerStateChange(e) {
            if(e.data == 2) {
                //play video immediately if paused
                self.player.playVideo()
            } else if(e.data == 0) {
                //when video ends move it to the end of current djs current playlist
                //take first track from playlist out
                var justPlayed = self.currentList.tracks.shift();
                //and add it to the back
                self.currentList.tracks.push(justPlayed);

                //post new current list order
                U.ajax('POST', '/api/playlistorder', function(playlist) {
                    //get the next dj spot
                    var nextDj = self.room.currentDj.spot < self.room.djs.length - 1 ? self.room.currentDj.spot + 1 : 0
                    setCurrentPlaylist(playlist)
                    self.update()
                    self.playTrackBy(self.room.djs[nextDj])
                }, self.currentList);
            }
        }

        //listen for user activity
        socket.on('room_users_changed', function(updatedRoom) {
            console.log('room_users_changed');
            if(self.userInRoom(updatedRoom)) {
                console.log('im in the room');
                //if the room is already loaded
                if(self.room) {
                    //update new audience avatars
                    self.findNewAvatars(self.room.audience, updatedRoom.audience)
                    //update new dj avatars
                    self.findNewAvatars(self.room.djs, updatedRoom.djs)
                } else {
                    //load all dj avatars
                    self.updateAvatars(updatedRoom.djs)
                    //load all audience avatars
                    self.updateAvatars(updatedRoom.audience)
                }

                if(self.currentList) {
                    //if currentList is ready (and everything else) update room now
                    self.updateRoom(updatedRoom)
                } else {
                    //otherwise save updated room but dont render yet
                    self.room = updatedRoom
                }
            }
        })

        //listen for track changes
        socket.on('room_track_changed', function(updatedRoom) {
            if(self.userInRoom(updatedRoom)) {
                //load youtube player with current track
                self.room = updatedRoom

                //play the current track
                if(self.player) {
                    self.player.loadVideoById(self.room.currentTrack._id)
                } else {
                    self.createPlayer()
                }
                
                self.update()
            }
        })

        //check which users avatars have not yet loaded
        findNewAvatars(oldRoomUsers, newRoomUsers) {
            var newUsers = []
            for(var i=0, l=newRoomUsers.length; i<l; i++) {
                var newUser = true
                for(var j=0, ll=oldRoomUsers.length; j<ll; j++) {
                    //console.log(newRoomUsers[i].googleId, oldRoomUsers[j].googleId)
                    if(newRoomUsers[i].googleId == oldRoomUsers[j].googleId) {
                        newUser = false
                    }
                }
                if(newUser) newUsers.push(newRoomUsers[i])
            }
            //load new avatars
            self.updateAvatars(newUsers)
        }

        //get user avatars from google
        updateAvatars(users) {
            for(var i=0, l=users.length; i<l; i++) {
                getGoogleAvatar(i, users[i].googleId, function(index, img) {
                    users[index].img = img
                    self.update()
                })
            }
        }

        createPlayer() {
            //init the youtube player
            self.player = new YT.Player('yt-player', {
                videoId: self.room.currentTrack._id,
                playerVars: {
                    //start: ??, //TODO: how do we get this? (time to start video at)
                    autoplay: 1,
                    controls: 0,
                    disablekb: 1,
                    modestbranding: 1,
                    rel: 0,
                    showinfo: 0
                },
                events: {
                    'onStateChange': self.onPlayerStateChange
                }
            })
        }

        //check if the current user is in the room provided
        userInRoom(room) {
            //only update room if it's the one user is in
            //is this really the best way to limit this?
            var isAud = U.getOne('_id', self.user._id, room.audience)
            var isDj = U.getOne('_id', self.user._id, room.djs)
            if(isAud || isDj) {
                return true
            } else {
                return false
            }
        }

        //refresh room with new data
        updateRoom(room) {
            //if the next dj should start playing
            var startNewDj = false
            if(room.currentDj && self.room) {
                //the last dj quit while playing
                if(self.room.currentDj) {
                    if(room.currentDj._id != self.room.currentDj._id) {
                        //start new dj after update
                        startNewDj = true
                    }
                }
            } else if(!self.room) {
                //no self.room defined, first room update
                startNewDj = true
            }

            //update new room data
            self.room = room

            //is dj spot open
            self.openDj = room.djs.length < 5 ? true : false
            //if you are djing, no open dj spot
            if(U.getOne('_id', self.user._id, room.djs)) {
                self.openDj = false
                self.userIsDj = true
            } else {
                self.userIsDj = false
            }

            //if the room has a dj currently playing a track
            if(room.currentDj != undefined) {
                //loop through djs to set which is playing
                for(var i=0, l=room.djs.length; i<l; i++) {
                    room.djs[room.currentDj.spot].isPlaying = true
                }

                //start new dj if old one quit
                if(startNewDj) {
                    self.playTrackBy(room.djs[room.currentDj.spot])
                }
            } else {
                //no djs
                if(self.player) {
                    self.player.stopVideo()
                    self.player.clearVideo()
                }
            }

            self.update()
        }
        
        //step up to dj
        becomeDj(e) {
            //remove user from local audience
            U.removeOne('_id', self.user._id, self.room.audience)
            //add user to local djs
            self.room.djs.push(self.user)
            //hide become dj button
            self.openDj = false

            //send updated room djs and audience
            U.ajax('PUT', '/api/roomusers/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
                //if the user is the only dj
                if(updatedRoom.djs.length == 1) {
                    //start playing the first song in their current playlist
                    self.playTrackBy(self.user);
                }
            }, {audience: self.room.audience, djs: self.room.djs})
        }

        //quit as dj
        quitDj(e) {
            //remove user from local djs
            U.removeOne('_id', self.user._id, self.room.djs)
            //add user to local audience
            self.room.audience.push(self.user)
            //hide become dj button
            self.openDj = true

            //send updated room djs and audience
            U.ajax('PUT', '/api/roomusers/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
            }, {audience: self.room.audience, djs: self.room.djs})
        }

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

        //go back to the lobby
        leaveRoom(e) {
            RiotControl.trigger('room.left_room', self.room)
        }

        //called from first dj stepping up
        //also from when current djs song ends
        playTrackBy(dj) {
            //if current user is the next dj to play
            if(dj.googleId == self.user.googleId) {
                //set the next current track to play in the room
                U.ajax('PUT', '/api/roomtrack/' + self.room._id, function(data) {
                    //socket emits room_track_changed
                }, {track: self.currentList.tracks[0]})
            }
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
    </script>
</room>