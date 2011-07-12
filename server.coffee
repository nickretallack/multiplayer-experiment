define [
    'socket.io'
    'express'
    'cs!player'
    'underscore'
], (socketio, express, Player) ->
    app = express.createServer()
    app.use express.static '.'

    players = {}

    io = socketio.listen app
    io.set 'log level', 1
    io.sockets.on 'connection', (socket) ->
        player = new Player
        players[socket.id] = player

        player_list = {}
        for id, player of players
            player_list[id] = player.position.components

        console.log player_list

        socket.emit 'player-list', 
            player_list:player_list
            your_id:socket.id

        socket.on 'disconnect', ->
            delete players[socket.id]
            # TODO: send leave message

        socket.on 'move', (data) ->
            player.position.components = data.position
            io.sockets.emit 'moved', 
                player_id:socket.id
                position:data.position


    
    app.listen 8085
