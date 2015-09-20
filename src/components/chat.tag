<chat>
    <p class="room-name">{room.name}</p>
    <div id="convo" class="convo">
        <p each={chatLog} class="message"><span class="user {color}">{username}:</span> <span class="text"> {message}</span></p>
    </div>
    <input class="chat-box" type="text" placeholder="chat" onkeyup={chatMessageChange} value={chatMessage}>

    <script>
        var self = this
        self.chatLog = []
        self.chatColors = [
            'green-text',
            'aqua-text',
            'pink-text',
            'purple-text',
            'blue-text',
            'brown-text'
        ]

        RiotControl.on('room.init', function(user, room) {
            self.user = user
            self.room = room
            self.chatLog = []
            console.log('room init')
            self.update()
        })

        RiotControl.on('update_room', function(room) {
            self.room = room
            self.update()
        })

        RiotControl.on('leave_room', function(stayInRoom) {
            self.chatLog = []
        })

        //listen for chat typing
        chatMessageChange(e) {
            self.chatMessage = e.target.value

            //hit enter key, post to server
            if(e.keyCode == 13 && self.chatMessage.trim().length > 0) {
                socket.emit('chat_message', {
                    googleId: self.user.googleId,
                    username: self.user.name,
                    color: self.getChatColor(),
                    message: encodeURIComponent(self.chatMessage.trim())
                })
                //clear message
                self.chatMessage = ''
            }
        }

        getChatColor() {
            var color
            //loop through chat log in reverse
            for (var i = self.chatLog.length - 1; i >= 0; i--) {
                //look for user in chat log
                if(self.user.name == self.chatLog[i].username) {
                    //save their last color
                    color = self.chatLog[i].color
                }
            }
            //if the last message did not use their color
            if(color) {
                if(color != self.chatLog[self.chatLog.length-1].color ||
                    self.user.name == self.chatLog[self.chatLog.length-1].username) {
                    return color
                }
            }

            //if user isnt in the chat log or their color was used
            //get them a new color
            var c, nc, cl = self.chatLog.length
            while(!c) {
                nc = Math.floor(Math.random()*self.chatColors.length)
                if(cl == 0) {
                    c = self.chatColors[nc]
                } else if(cl == 1 && nc != self.chatLog[0].color) {
                    c = self.chatColors[nc]
                } else if(nc != self.chatLog[cl-1].color && nc != self.chatLog[cl-2].color) {
                    c = self.chatColors[nc]
                } else {
                    //console.log('tried to be prev color')
                }
            }
            return c
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
    </script>
</chat>