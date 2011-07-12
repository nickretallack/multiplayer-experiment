define [
    'socket.io'
    'express'
], (socketio, express) ->
    app = express.createServer()
    app.use express.static '.'

    players = []

    io = socketio.listen app
    io.sockets.on 'connection', (socket) ->
        console.log socket, "CONNECTED"

    
    app.listen 8085
