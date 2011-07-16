define [
    'socket.io'
    'express'
    'cs!models'
], (socketio, express, models) ->
    app = express.createServer()
    app.use express.static '.'

    players = new models.PlayerCollection

    io = socketio.listen app
    io.set 'log level', 1
    io.sockets.on 'connection', (socket) ->
        player = new models.Player
        player.set id:socket.id
        console.log socket.id
        players.add player
        player_list = players.toJSON()
        
        console.log player_list
        socket.emit 'player-list', 
            player_list:player_list
            your_id:socket.id

        io.sockets.emit 'joined',
            player.toJSON()

        socket.on 'disconnect', ->
            players.remove player
            # TODO: send leave message

        socket.on 'move', (data) ->
            player.position.elements = data.position
            io.sockets.emit 'moved', 
                player_id:socket.id
                position:data.position


    
    app.listen 8085
