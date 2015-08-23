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
                        <iframe id="yt-preview" if={preview} class="preview-player" type="text/html" 
                            width="100%" height="auto" 
                            frameborder="0"
                            src="http://www.youtube.com/embed/{id.videoId}?autoplay=1&enablejsapi=1">
                        </iframe>
                        <div class="preview">
                            <img hide={preview} onclick={previewTrack} src="{snippet.thumbnails.medium.url}" width="100%" alt="" />
                            <div class="preview-arrow"></div>
                        </div>
                        <p class="title">{snippet.title}</p>
                        <p hide={added} class="add" onclick={addToPlaylist}>+ Add to playlist</p>
                        <p show={added} class="added">In playlist!</p>
                    </li>
                </ul>
            </div>

            <!-- playlists -->
            <div id="playlists" class="container {selectingList?'list-open':''}">
                <div show={currentList && !creatingPlaylist} hide={playlistToDelete} class="playlists">
                    <div class="dropdown">
                        <div class="arrow-holder">
                            <div class="arrow-down"></div>
                            <div class="arrow-up"></div>
                        </div>
                        <div class="selected" onclick={openPlaylists}>
                            <p>{currentList.name}</p>
                        </div>
                        <div class="options">
                            <ul>
                                <li onclick={closePlaylists}>Select a playlist</li>
                                <li each={playlists}>
                                    <span class="delete" title="Delete" onclick={toggleDeletePlaylist}>x</span>
                                    <span class="spacer">&nbsp;</span> 
                                    <span class="title" onclick={selectPlaylist}>{name}</span>
                                </li>
                            </ul>
                            <div class="new-playlist">
                                <button onclick={togglePlaylistForm}>+ Create new playlist</button>
                            </div>
                        </div>
                    </div>
                    <div class="track-holder">
                        <ul class="tracks {userIsPlayling?'playing':''}">
                            <li class="playlist-track" each={currentList.tracks} onmousedown={startTrackDrag}>
                                <span class="delete" title="Delete" onclick={removeFromPlaylist}>x</span>
                                <span class="num">{index}.</span> 
                                <span class="title">{title}</span>
                                <span class="arrow-up" onclick={moveTrackToTop}></span>
                            </li>
                        </ul>
                    </div>
                </div>

                <div show={creatingPlaylist} class="create-playlist {postingPlaylist?'posting':''}">
                    <p class="name-label">Give your new playlist a name:</p>
                    <input class="playlist-name" type="text" placeholder="playlist name" onkeyup={playlistNameChange} value={newPlaylistName}>

                    <p class="cancel-btn" onclick={togglePlaylistForm}>Cancel</p>
                    <button class="create-btn" type="button" onclick={createPlaylist}>Create</button>
                </div>

                <div show={playlistToDelete} class="delete-playlist">
                    <p class="warning">Really delete <span>{playlistToDelete.name}</span>?</p>
                    <p class="cancel-btn" onclick={toggleDeletePlaylist}>Cancel</p>
                    <button class="delete-btn" type="button" onclick={deletePlaylist}>Delete</button>
                </div>

                <p class="user"><span class="name">{user.name}</span> - <span class="leave" onclick={leaveRoomClicked}>Leave room</span></p>
            </div>
        </div>

        <!-- chat -->
        <div class="chat">
            <p class="room-name">{room.name}</p>
            <div id="convo" class="convo">
                <p each={chatLog} class="message"><span class="user">{username}:</span> <span class="text"> {message}</span></p>
            </div>
            <input class="chat-box" type="text" placeholder="chat" onkeyup={chatMessageChange} value={chatMessage}>
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
                    <div each={room.djs} class="avatar {isPlaying?'playing':''} {like?'like':''} {likeLeft?'likeLeft':''}">
                        <img src="{img || 'assets/img/avatar.png'}" width="42" height="42" alt="" />
                        <p class="avatar-name">{name}</p>
                    </div>
                    <div class="be-dj" show={openDj} onclick={becomeDj}>
                        <button>Start to DJ</button>
                    </div>
                </div>
                <button class="quit-dj" show={userIsDj} onclick={quitDjClicked}>Quit DJ</button>
                <div class="overlay" show={room.currentTrack}>
                    <p class="title">{room.currentTrack.title}</p>
                    <button class="mute" onclick={toggleMute}>
                        <span hide={playerMuted}>Mute</span><span show={playerMuted}>Unmute</span>
                    </button>
                    <button class="skip" show={userIsPlayling} onclick={prepNextTrack}>Skip song</button>
                    <button class="like" onclick={likeTrack}>Dance</button>
                    <div class="progress-bar">
                        <div class="bg"></div>
                        <div id="progress-bar" class="bar"></div>
                    </div>
                </div>
            </div>
            <div class="audience">
                <div each={room.audience} class="avatar {like?'like':''} {likeLeft?'likeLeft':''}">
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
        self.playlistToDelete = undefined
        self.chatLog = []

        RiotControl.on('render_room', function(user, room) {
            self.user = user
            //let self.room get set in updateRoom

            console.log('render_room')

            //get users playlists
            self.getUserPlaylists(function() {
                //set current playlist to the first one
                self.setCurrentPlaylist(self.playlists[0])

                //update room after lists are loaded
                self.updateRoom(room)

                //set up youtube player
                self.setupPlayer(room)
            })

            //leave room if the user closes the window
            //also happens on refresh
            window.onbeforeunload = function() {
                self.leaveRoom()
            }

            self.likeTimer = setInterval(function() {
                for(var i=0, l=self.room.audience.length; i<l; i++) {
                    if(self.room.audience[i].like) {
                        self.room.audience[i].likeLeft = !self.room.audience[i].likeLeft
                    }
                }
                for(var j=0, l=self.room.djs.length; j<l; j++) {
                    if(self.room.djs[j].like) {
                        self.room.djs[j].likeLeft = !self.room.djs[j].likeLeft
                    }
                }
                self.update()
            }, 666)

            //socket will also emit room_users_changed at this point
        })

        RiotControl.on('force_leave_room', function() {
            self.leaveRoom()
        })

        //gets the users playlist data
        getUserPlaylists(callback) {
            var listUrl = '/api/playlists/'
            listUrl += self.user.playlists.join(',')

            U.ajax('GET', listUrl, function(lists) {
                self.playlists = lists
                if(callback) callback()
            })
        }

        //handle youtube player state changes
        onPlayerStateChange(e) {
            if(e.data == 2) {
                //play video immediately if paused
                self.player.playVideo()
            } else if(e.data == 1) {
                if(self.lastVideoState != 1 && self.lastVideoState != 3) {
                    //get time passed in seconds from current track start date to now
                    var startTime = 0
                    startTime = (new Date().getTime() - new Date(self.room.currentTrack.date).getTime()) / 1000
                    self.player.seekTo(startTime + 0.666) //add 0.666 to fudge a little load time
                }

                //video is playing
                if(self.room.djs.length == 0) {
                    self.stopVideo()
                }

                self.clearProgress()

                //start progress bar
                self.progressTimer = setInterval(function() {
                    var percent = self.player.getCurrentTime() / self.player.getDuration() * 100
                    document.getElementById('progress-bar').style.width = percent + '%'
                }, 50)
            } else if(e.data == 0) {
                self.prepNextTrack()
            }

            //save video state
            self.lastVideoState = e.data
        }

        toggleMute() {
            if(self.player.isMuted()) {
                self.player.unMute()
            } else {
                self.player.mute()
            }
            self.playerMuted = !self.playerMuted
        }

        stopVideo() {
            if(self.player) {
                self.player.stopVideo()
                self.player.clearVideo()
                self.clearProgress()
            }
        }

        clearProgress() {
            try{
                clearInterval(self.progressTimer)
            } catch(e) {}
        }

        prepNextTrack() {
            //check if user was dj
            if(self.userIsPlayling) {
                //when video ends move it to the end of current djs current playlist
                //take first track from playlist out
                var justPlayed = self.currentList.tracks.shift()
                //and add it to the back
                self.currentList.tracks.push(justPlayed)
                
                //post new current list order
                U.ajax('POST', '/api/playlistorder', function(playlist) {
                    //get the next dj spot
                    var nextDj = self.room.currentDj.spot < self.room.djs.length - 1 ? self.room.currentDj.spot + 1 : 0
                    self.setCurrentPlaylist(playlist)
                    self.playTrackBy(self.room.djs[nextDj], nextDj)
                    self.update()
                }, self.currentList)
            } else {
                //if user is not dj
                var nextDj = self.room.currentDj.spot < self.room.djs.length - 1 ? self.room.currentDj.spot + 1 : 0
                self.playTrackBy(self.room.djs[nextDj], nextDj)
                self.update()
            }
        }

        //user likes the track!
        likeTrack(e) {
            var roomUser;
            //get the users object in the room
            if(self.userIsDj) {
                roomUser = U.getOne('googleId', self.user.googleId, self.room.djs)
            } else {
                roomUser = U.getOne('googleId', self.user.googleId, self.room.audience)
            }
            //set users like
            roomUser.like = true
            roomUser.likeLeft = true

            //update room users
            U.ajax('PUT', '/api/roomusers/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
            }, {audience: self.room.audience, djs: self.room.djs})
        }

        clearLikes() {
            clearInterval(self.likeTimer)
            //loop through all users in room and set their like to false
            for(var i=0, l=self.room.audience.length; i<l; i++) {
                self.room.audience[i].like = false
                delete self.room.audience[i].like
            }
            for(var j=0, l=self.room.djs.length; j<l; j++) {
                self.room.djs[j].like = false
                delete self.room.djs[j].likeLeft
            }
            //update room users
            U.ajax('PUT', '/api/roomusers/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
            }, {audience: self.room.audience, djs: self.room.djs})
        }

        //listen for chat typing
        chatMessageChange(e) {
            self.chatMessage = e.target.value

            //hit enter key, post to server
            if(e.keyCode == 13 && self.chatMessage.trim().length > 0) {
                socket.emit('chat_message', {
                    googleId: self.user.googleId,
                    username: self.user.name,
                    message: encodeURIComponent(self.chatMessage.trim())
                })
                //clear message
                self.chatMessage = ''
            }
        }

        //update chat
        socket.on('new_chat_message', function(newMessage) {
            var isDj = U.getOne('googleId', newMessage.googleId, self.room.djs);
            var isAud = U.getOne('googleId', newMessage.googleId, self.room.audience);
            
            //only update if chatter is in the room
            if(isDj || isAud) {
                //dont let the chat log get too long
                if(self.chatLog.length > 200) {
                    self.chatLog.shift()
                }

                newMessage.message = decodeURIComponent(newMessage.message)

                //update chat log
                self.chatLog.push(newMessage)
                self.update()

                //scroll chat to bottom
                document.getElementById('convo').scrollTop = 10000;
            }
        })

        //listen for user activity
        socket.on('room_users_changed', function(updatedRoom) {
            if(self.userInRoom(updatedRoom)) {
                //if the room is already loaded
                if(self.room) {
                    //update new audience avatars
                    self.findNewAvatars(self.room.audience, updatedRoom.audience)
                    //update new dj avatars
                    self.findNewAvatars(self.room.djs, updatedRoom.djs)
                } else {
                    //load all dj avatars
                    self.updateAvatars(updatedRoom.djs)
                    //load all audience (avatars
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
            self.clearProgress()
            console.log('room_track_changed')
            self.clearLikes()
            self.setupPlayer(updatedRoom)
        })

        //set up player to play a video
        setupPlayer(room) {
            //if user is in the room, and there is a current track
            if(self.userInRoom(room) && room.currentTrack) {
                //load youtube player with current track
                self.room = room
                //play the current track if there is one
                if(self.player) {
                    self.player.loadVideoById(room.currentTrack._id)
                    self.player.playVideo();
                } else {
                    self.createPlayer()
                }

                self.update()
                //console.log(self.room)
            }
        }

        //check which users avatars have not yet loaded
        findNewAvatars(oldRoomUsers, newRoomUsers) {
            var newUsers = []
            for(var i=0, l=newRoomUsers.length; i<l; i++) {
                var newUser = true
                for(var j=0, ll=oldRoomUsers.length; j<ll; j++) {
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
            self.playerMuted = false
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
                    if(room.currentDj.googleId != self.room.currentDj.googleId) {
                        //start new dj after update
                        startNewDj = true
                    }
                }
            } else if(!self.room) {
                //no self.room defined, first room update
                //this starts the current track video when entering a room
                startNewDj = true
            }

            //update new room data
            self.room = room

            //if you are djing, no open dj spot
            if(U.getOne('_id', self.user._id, room.djs)) {
                self.userIsDj = true
            } else {
                self.userIsDj = false
            }

            //is dj spot open
            self.checkOpenDjSpot()


            //if the room has a dj currently playing a track
            if(room.currentDj != undefined) {
                //loop through djs to set which is playing
                //this is only to update the dj avatar isPlaying vertical position
                for(var i=0, l=room.djs.length; i<l; i++) {
                    room.djs[i].isPlaying = false
                }
                //set current dj flag on dj
                room.djs[room.currentDj.spot].isPlaying = true

                //strat the video if needed
                if(startNewDj) {
                    self.playTrackBy(room.djs[room.currentDj.spot], room.currentDj.spot)
                }
            } else {
                //no djs
                if(self.player) {
                    self.stopVideo()
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
                    self.playTrackBy(self.user, 0);
                }
            }, {audience: self.room.audience, djs: self.room.djs, changeDj: true})
        }

        quitDjClicked(e) {
            self.quitDj(true)
        }

        //quit as dj
        quitDj(stayInRoom) {
            //if user was dj, stop video
            if(self.userIsPlayling) {
                self.userIsPlayling = false
                self.stopVideo()
            }

            //remove user from local djs
            U.removeOne('_id', self.user._id, self.room.djs)
            //add user to local audience
            self.room.audience.push(self.user)
            //hide become dj button
            self.openDj = true
            //if you were the last dj, clear current track
            if(self.room.djs.length == 0) {
                self.room.currentTrack = undefined
            }

            if(stayInRoom) {
                U.ajax('PUT', '/api/roomusers/' + self.room._id, function(updatedRoom) {
                    //updated room is sent via socket as room_users_changed
                }, {audience: self.room.audience, djs: self.room.djs, changeDj: true})
            }
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
                self.update()
            })
        }

        //close playlist dropdown
        closePlaylists(e) {
            self.selectingList = false
        }

        //show/hide the delete playlist confirmation
        toggleDeletePlaylist(e) {
            self.playlistToDelete = e.item
        }

        //delete the playlist
        deletePlaylist(e) {
            U.ajax('POST', '/api/removeplaylist', function(user) {
                self.playlistToDelete = undefined
                self.user = user
                self.getUserPlaylists(self.update)
            }, {
                user: self.user,
                playlist: self.playlistToDelete
            })
        }

        //toggle create playlist form
        togglePlaylistForm(e) {
            self.creatingPlaylist = !self.creatingPlaylist
        }

        //new playlist name
        playlistNameChange(e) {
            self.newPlaylistName = e.target.value
        }

        leaveRoomClicked(e) {
            self.leaveRoom(true)
        }

        //go back to the lobby
        leaveRoom(forceLobby) {
            window.onbeforeunload = undefined

            //if user was dj, quit dj
            if(self.userIsDj) self.quitDj()

            //remove user from local audience
            U.removeOne('_id', self.user._id, self.room.audience)

            //clear video
            self.stopVideo()

            //clear chat
            self.chatLog = []
            console.log('leaving room')
            //send updated room djs and audience
            U.ajax('PUT', '/api/roomusers/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
                //if leaving room from leave room link, switch to lobby
                if(forceLobby) RiotControl.trigger('room.left_room')
            }, {audience: self.room.audience, djs: self.room.djs, changeDj: true})
        }

        //called from first dj stepping up
        //also from when current djs song ends
        playTrackBy(dj, spot) {
            //reset uesr playing
            self.userIsPlayling = false

            //if current user is the next dj to play
            if(dj.googleId == self.user.googleId) {
                self.userIsPlayling = true
                //set the next current track to play in the room
                //send the first item of their current playlist to the room
                U.ajax('PUT', '/api/roomtrack/' + self.room._id, function(data) {
                    //socket emits room_track_changed
                }, {
                    track: self.currentList.tracks[0], 
                    date: new Date().toString(),
                    dj: {spot: spot, _id: dj.googleId}
                })
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
                self.newPlaylistName = ''
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
            self.checkOpenDjSpot()
            self.update()
        }

        checkOpenDjSpot() {
            self.openDj = false
            //if user doesnt have any tracks in their playlist
            if(self.currentList) {
                if(self.currentList.tracks.length > 0 && self.room.djs.length < 5 && !self.userIsDj) {
                    self.openDj = true
                }
            }
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

        previewTrack(e) {
            //loop through current results
            for(var i=0, l=self.searchResults.length; i<l; i++) {
                //check if result was clicked
                if(e.item.id.videoId == self.searchResults[i].id.videoId) {
                    //if yes, set preview to true
                    self.searchResults[i].preview = true
                } else {
                    //otherwise false
                    self.searchResults[i].preview = false
                }
            }
            self.update()

            setTimeout(function() {
                //init the preview youtube player
                self.previewPlayer = new YT.Player('yt-preview', {
                    playerVars: {
                        autoplay: 1,
                        disablekb: 1,
                        modestbranding: 1,
                        rel: 0,
                        showinfo: 0
                    },
                    events: {
                        'onStateChange': self.onPreviewStateChange
                    }
                })
            }, 100)
        }

        onPreviewStateChange(e) {
            //if the room player exists
            if(self.player && !self.playerMuted) {
                if(e.data == 1) {
                    //if preview playing, mute room player
                    self.player.mute()
                } else if(e.data == 0 || e.data == 2) {
                    //if preview paused or ended, unmute room player
                    self.player.unMute()
                } else {

                }
            }
        }

        closeSearch(e) {
            self.query = ''
            self.searching = false
            window.clearTimeout(searchTimer)
            self.searchResults = []
            //unmute room player
            if(self.player && !self.playerMuted) self.player.unMute()
        }

        //adds a track to the end of users current playlist
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

        //remove a clicked track from a playlist
        removeFromPlaylist(e) {
            U.ajax('POST', '/api/removetrack', function(updatedPlylist) {
                self.setCurrentPlaylist(updatedPlylist)
                self.update()
            }, {
                playlistId: self.currentList._id,
                trackId: e.item._id
            })
        }

        //on mouse down on track
        startTrackDrag(e) {
            //prevent user from dragging current playing track
            if(self.userIsPlayling && e.item.index == 0) return
            
            var t = e.currentTarget
            var startY = e.clientY
            var oldClass = t.className
            var newSpot = oldSpot = e.item.index - 1
            
            t.className = t.className + ' dragging'

            //follow mouse move
            document.onmousemove = function(e) {
                t.style.top = (e.clientY - startY) + 'px'
                t.style.pointerEvents = 'none'
            }

            //on release
            document.body.onmouseup = function(e) {

                t.className = oldClass
                t.style.top = '0px';

                //find parent playlist-track
                if(U.hasClass(e.target.parentElement, 'playlist-track')) {
                    //get playlist-track index
                    newSpot = U.getElementIndex(e.target.parentElement)
                } else if(U.hasClass(e.target, 'playlist-track')) {
                    newSpot = U.getElementIndex(e.target)
                } else {
                    //do nothing
                    self.stopDrag()
                    t.style.pointerEvents = 'auto'
                    return
                }

                //if user tries to move track into currently playing track
                //set new spot to 1 instead of 0
                if(self.userIsPlayling && newSpot == 0) newSpot = 1
                

                //reorder track array with track in newSpot position
                U.moveListItem(self.currentList.tracks, oldSpot, newSpot)
                self.setCurrentPlaylist(self.currentList)
                self.update()

                //post new current list order
                U.ajax('POST', '/api/playlistorder', function(playlist) {
                    self.setCurrentPlaylist(playlist)
                    self.update()
                }, self.currentList)

                self.stopDrag()
                t.style.pointerEvents = 'auto'
            }
        }

        //when mouse is released after dragging
        stopDrag() {
            //remove handlers
            document.body.onmouseup = undefined
            document.onmousemove = undefined
            document.getElementById('playlists').mouseleave = undefined
        }

        //clicking arrow up on playlist track item
        moveTrackToTop(e) {
            self.stopDrag()

            //remove topped item
            var track = self.currentList.tracks.splice(e.item.index - 1, 1)[0]
            //if user is playing track
            if(self.userIsPlayling) {
                //add to 2nd spot
                self.currentList.tracks.splice(1, 0, track)
            } else {
                //if not playing, add item to top
                self.currentList.tracks.unshift(track)
            }

            //set new playlist order
            self.setCurrentPlaylist(self.currentList)

            //post new current list order
            U.ajax('POST', '/api/playlistorder', function(playlist) {
                self.setCurrentPlaylist(playlist)
                self.update()
            }, self.currentList)
        }
    </script>
</room>




