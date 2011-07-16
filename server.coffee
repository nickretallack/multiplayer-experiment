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
        player = new models.Player
        player.set id:socket.id
        players.add player

        socket.emit 'player-list', 
            player_list:players.toJSON()
            your_id:socket.id

        console.log "JOINED", JSON.stringify(player.toJSON()), socket
        io.sockets.emit 'joined', player.toJSON()

        socket.on 'disconnect', ->
            players.remove player
            io.sockets.emit 'left', player.id
            # TODO: send leave message

        socket.on 'move', (data) ->
            player.set position:$V data.position...
            io.sockets.emit 'moved', 
                player_id:socket.id
                position:data.position


    
    app.listen 8085
