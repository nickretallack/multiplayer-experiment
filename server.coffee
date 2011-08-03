define [
    'socket.io'
    'express'
    'cs!models'
    'library/sylvester'
    'pg'
    'cs!database'
], (socketio, express, models, sylvester, pg, database) ->
    $V = sylvester.$V
    app = express.createServer()
    app.use express.static '.'
    db = new pg.Client 'tcp://game:game@localhost/game'
    db.connect()

    database.set_client db
    #database.create_player('bob','password', (id) -> console.log(id))

    players = new models.PlayerCollection

    io = socketio.listen app
    io.set 'log level', 1
    io.sockets.on 'connection', (socket) ->

        socket.emit 'player-list', 
            player_list:players.toJSON()

        socket.on 'register', (credentials, next) ->
            player = database.create_player credentials.name, credentials.password, (player) ->
                console.log "registered as", JSON.stringify player
                recognized player, next if player
            , (error) ->
                if error.message is 'duplicate key value violates unique constraint "credentials_login_key"'
                    next type:'error', message: "Couldn't register because that name is taken"

        # NOTE: in the future this wont be 'once'.  You should be able to switch users without reconnecting
        socket.on 'login', (credentials, next) -> 
            player = database.authenticate credentials.name, credentials.password, (player) ->
                console.log "Logged in as", JSON.stringify player
                if player
                    recognized player, next
                else
                    next type:'error', message:"Auth Failed"

        recognized = (player, next) ->
            players.add player

            # NOTE: in the future this should also send you the place you're in...
            # though maybe it'd be better to have you get that with a regular ajax request?
            # Wonder if sockets would make streaming easier or not.  You can definitely stream with ajax.
            socket.emit 'recognized'
                player_id:player.id
            socket.broadcast.emit 'joined', player.toJSON()

            socket.once 'disconnect', ->
                players.remove player
                socket.broadcast.emit 'left', player.id

            socket.on 'move', (data) ->
                player.set position:$V data.position...
                socket.broadcast.emit 'moved', 
                    player_id:player.id
                    position:data.position

            next type:'success'
        
        socket.on 'added-obstacle', (obstacle) ->
            # TODO: do something with it?  idk.  For now just volley
            socket.broadcast.emit 'added-obstacle', obstacle
    
    app.listen 8085
