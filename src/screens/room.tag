<room>
    <section>
        <playlists />
        <chat />

        <!-- stage -->
        <div class="stage">
            <div class="video-holder">
                <div class="video">
                    <div id="yt-player">
                        <img src="assets/img/no-djs.png" width="100%" alt="" />
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
                    <div class="title"><p>{room.currentTrack.title}</p></div>
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

        RiotControl.on('render_room', function(user, room) {
            self.user = user

            //leave room if the user closes the window
            //also happens on refresh
            window.onbeforeunload = function() {
                self.leaveRoom()
            }

            //update user in components
            RiotControl.trigger('room.init', user)

            //update room after lists are loaded
            self.renderRoom(room)

            //socket will also emit room_users_changed at this point
        })

        //stay informed of playlist changes
        RiotControl.on('playlists.set_current_list', function(list) {
            self.currentList = list
            self.checkOpenDjSpot()
            self.update()
        })

        RiotControl.on('leave_room', function(stayInRoom) {
            self.leaveRoom(stayInRoom)
        })

        RiotControl.on('update_user', function(user) {
            self.user = user
            self.update()
        })

        RiotControl.on('update_room', function(room) {
            self.room = room
            self.update()
        })

        //sets up the like dance timer
        setupLikeTimer() {
            self.likeTimer = setInterval(function() {
                
                for(var i=0, l=self.room.audience.length; i<l; i++) {
                    if(self.room.audience[i].like) {
                        self.room.audience[i].likeLeft = !self.room.audience[i].likeLeft
                    }
                }
                
                for(var j=0, l=self.room.djs.length; j<l; j++) {
                    if(self.room.djs[j]) {
                        self.room.djs[j].likeLeft = !self.room.djs[j].likeLeft
                    }
                }
                self.update()
            }, 666)
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

        //can/should only be called by the current playing user, when their song ends
        prepNextTrack() {
            //reset uesr playing
            self.userIsPlayling = false

            //tell playlist to update
            RiotControl.trigger('room.user_track_played')

            //update next room dj
            //get the next dj spot
            var nextDjSpot = self.room.currentDj.spot < self.room.djs.length - 1 ? self.room.currentDj.spot + 1 : 0

            var nextDj = {nextDjSpot: nextDjSpot, nextDjId: self.room.djs[nextDjSpot].googleId}
            //set the next currentDj in the room
            //updateRoom should start them playing
            U.ajax('PUT', '/api/updateroom/' + self.room._id, function(updatedRoom) {
                //will fire room_users_changed
            }, nextDj)
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
            U.ajax('PUT', '/api/updateroom/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
            }, {audience: self.room.audience, djs: self.room.djs})
        }

        //clearLikes from in room
        clearLikes() {
            //stop timer
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
            U.ajax('PUT', '/api/updateroom/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
            }, {audience: self.room.audience, djs: self.room.djs})
        }

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
                    self.renderRoom(updatedRoom)
                    try {
                        console.log('prepped next track ' + updatedRoom.currentDj.googleId)
                    } catch(e) {

                    }
                } else {
                    //otherwise save updated room but dont render yet
                    RiotControl.trigger('update_room', updatedRoom)
                }
            }
        })

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
                    //autoplay: 1,
                    controls: 0,
                    disablekb: 1,
                    modestbranding: 1,
                    rel: 0,
                    showinfo: 0
                },
                events: {
                    'onReady': self.onPlayerReady,
                    'onStateChange': self.onPlayerStateChange
                }
            })
            self.playerMuted = false
        }

        //only called from initial player creation
        onPlayerReady(e) {
            console.log('player ready')
            if(self.autoPlay) {
                self.player.playVideo()
                self.autoPlay = false
            }
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
                    console.log('seeking to ' + startTime + 0.666)
                    //only seek if not playing track
                    if(!self.userIsPlayling) self.player.seekTo(startTime + 0.666) //add 0.666 to fudge a little load time
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
                //if the user was playing, prep next track to play
                if(self.userIsPlayling) self.prepNextTrack()
            }

            //save video state
            self.lastVideoState = e.data
        }

        //listen for track changes
        socket.on('room_track_changed', function(updatedRoom) {
            self.clearProgress()
            self.clearLikes()
            self.setupLikeTimer()
            self.setupPlayer(updatedRoom)
        })

        //set up player to play a video
        setupPlayer(room) {
            //if user is in the room, and there is a current track
            if(self.userInRoom(room) && room.currentTrack) {
                //load youtube player with current track
                RiotControl.trigger('update_room', room)
                //play the current track if there is one
                if(self.player) {
                    self.player.loadVideoById(room.currentTrack._id)
                    self.player.playVideo();
                } else {
                    self.autoPlay = true
                    self.createPlayer()
                }

                self.update()
            }
        }

        //check if the current user is in the room provided
        userInRoom(room) {
            if(!self.user) return false
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
        renderRoom(room) {
            //if the next dj should start playing
            var startNewDj = false
            if(room.currentDj && self.room) {
                
                //the last dj quit while playing
                if(self.room.currentDj) {
                    if(room.currentDj.googleId != self.room.currentDj.googleId) {
                        //start new dj if user is newly assigned dj
                        if(room.currentDj.googleId == self.user.googleId) {
                            startNewDj = true
                        }
                    }
                }
                
            }/* else if(!self.room) {
                //no self.room defined, first room update
                //this starts the current track video when entering a room
                //startNewDj = true
                console.log('eh')
                self.createPlayer()
                console.log('eh22')
                self.update()
            }*/

            //update new room data
            RiotControl.trigger('update_room', room)

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

                //start the video if needed
                if(startNewDj) {
                    self.playMyNextTrack(self.user, room.currentDj.spot)
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
            U.ajax('PUT', '/api/updateroom/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
                //if the user is the only dj
                if(updatedRoom.djs.length == 1) {
                    //start playing the first song in their current playlist
                    console.log('im DJ!')
                    self.playMyNextTrack(self.user, 0);
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
                U.ajax('PUT', '/api/updateroom/' + self.room._id, function(updatedRoom) {
                    //updated room is sent via socket as room_users_changed
                }, {audience: self.room.audience, djs: self.room.djs, changeDj: true})
            }
        }

        //go back to the lobby
        leaveRoom(forceLobby) {
            window.onbeforeunload = undefined
            clearInterval(self.likeTimer)
            console.log('leave1')
            //if user was dj, quit dj
            if(self.userIsDj) self.quitDj()

            //remove user from local audience
            U.removeOne('_id', self.user._id, self.room.audience)
            console.log('leave2')
            //clear video
            self.stopVideo()
            console.log('leave3')
            //clear chat
            self.chatLog = []
            console.log('leaving room')
            //send updated room djs and audience
            U.ajax('PUT', '/api/updateroom/' + self.room._id, function(updatedRoom) {
                //updated room is sent via socket as room_users_changed
                //if leaving room from leave room link, switch to lobby
                if(forceLobby) RiotControl.trigger('room.left_room')
            }, {audience: self.room.audience, djs: self.room.djs, changeDj: true})
        }

        //called from first dj stepping up
        //also from when current djs song ends
        playMyNextTrack(dj, spot) {
            
            //make sure local room has correct dj
            self.room.currentDj = {spot: spot, googleId: dj.googleId}

            //make sure user has a track to play
            if(self.currentList.tracks) {
                self.userIsPlayling = true
                //set the next current track to play in the room
                //send the first item of their current playlist to the room
                var djData = {
                    track: self.currentList.tracks[0], 
                    date: new Date().toString()
                };
                
                U.ajax('PUT', '/api/roomtrack/' + self.room._id, function(data) {
                    //socket emits room_track_changed
                    console.log('changed room track')
                }, djData)
            } else {
                //if they dont have a track ready, quit and stay in room
                quitDj(true)
            }
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
    </script>
</room>