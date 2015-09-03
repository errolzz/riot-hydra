<playlists>
    <input class="search" onkeyup={searchChanged} type="text" placeholder="search music" value={query}>

    
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
                    <li class="playlist-track" each={currentList.tracks}>
                        <span class="delete" title="Delete" onclick={removeFromPlaylist}>x</span>
                        <span class="num">{index}.</span> 
                        <span class="title" onmousedown={startTrackDrag}>{title}</span>
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

    <script>
        var self = this
        self.creatingPlaylist = false
        self.playlistToDelete = undefined

        RiotControl.on('room.init', function(user) {
            self.user = user
            
            //get users playlists
            self.getUserPlaylists(function() {
                //set current playlist to the first one
                self.setCurrentPlaylist(self.playlists[0])
                console.log(self.playlists)
            })
        })

        RiotControl.on('room.user_track_played', function() {
            //when video ends move it to the end of current djs current playlist
            //take first track from playlist out
            var justPlayed = self.currentList.tracks.shift()

            //and add it to the back
            self.currentList.tracks.push(justPlayed)
            
            //post new current list order
            U.ajax('POST', '/api/playlistorder', function(playlist) {
                //update users playlist
                self.setCurrentPlaylist(playlist)
                self.update()
            }, self.currentList)
        })

        RiotControl.on('update_user', function(user) {
            self.user = user
            self.update()
        })

        //gets the users playlist data
        getUserPlaylists(callback) {
            var listUrl = '/api/playlists/'
            listUrl += self.user.playlists.join(',')

            U.ajax('GET', listUrl, function(lists) {
                self.playlists = lists
                callback()
            })
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
            self.update()

            RiotControl.trigger('playlists.set_current_list', self.currentList);
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
                RiotControl.trigger('update_user', user)
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
            q += '&videoCategoryId=10&maxResults=20&videoEmbeddable=true&videoSyndicated=true'
            q += '&key=AIzaSyBRzzVaMuLFIKLA2MAcbmEWVbx5JWXmxSE&q='
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
            console.log('removing from '+self.currentList._id)
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
            console.log('dragging')
            //prevent user from dragging current playing track
            if(self.userIsPlayling && e.item.index == 0) return
            
            var t = e.currentTarget.parentElement
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
</playlists>