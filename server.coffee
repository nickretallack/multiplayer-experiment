define [
    'socket.io'
    'express'
    'cs!models'
    'library/sylvester'
], (socketio, express, models, sylvester) ->
    $V = sylvester.$V
    app = express.createServer()
    app.use express.static '.'

    players = new models.PlayerCollection

    io = socketio.listen app
    io.set 'log level', 1
    io.sockets.on 'connection', (socket) ->

        socket.emit 'player-list', 
            player_list:players.toJSON()

        # NOTE: in the future this wont be 'once'.  You should be able to switch users without reconnecting
        socket.once 'login', -> 
            player = new models.Player
            player.set id:socket.id
            players.add player

            # NOTE: in the future this should also send you the place you're in...
            # though maybe it'd be better to have you get that with a regular ajax request?
            # Wonder if sockets would make streaming easier or not.  You can definitely stream with ajax.
            socket.emit 'recognized'
                player_id:socket.id
            socket.broadcast.emit 'joined', player.toJSON()

            socket.once 'disconnect', ->
                players.remove player
                socket.broadcast.emit 'left', player.id

            socket.on 'move', (data) ->
                player.set position:$V data.position...
                socket.broadcast.emit 'moved', 
                    player_id:socket.id
                    position:data.position
    
    app.listen 8085
