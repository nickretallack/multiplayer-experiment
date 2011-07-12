define [
    'library/jquery'
    'library/mustache'
    'cs!library/keydown'
    'cs!library/vector'
    'cs!player'
], ($, mustache, KEYS, Vector, Player) ->
    console.log "WTF"
    render = mustache.to_html
    socket = io.connect('http://localhost')
    your_id = null
    player = null

    motions =
        "up": new Vector(0,-1)
        "down": new Vector(0,1)
        "left": new Vector(-1,0)
        "right": new Vector(1,0)

    speed = 5

    class PlayerView
        template:"""<div class="player"></div>"""
        constructor: (@model) ->
            @el = $ @template
            $(document.body).append @el
        update: ->
            motion = new Vector 0,0
            for key, vector of motions
                if KEYS[key]
                    motion = motion.add vector
            new_position = @model.position.add motion.scale(speed)
            unless new_position.equals @model.position
                socket.emit 'move', position:new_position.components
            
        draw: ->
            @el.css @model.position.as_css()


    players = {}
    player_views = {}

    console.log socket

    socket.on 'moved', (data) ->
        player = players[data.player_id]
        player.position.components = data.position

    socket.on 'player-list', (data) ->
        your_id = data.your_id
        for id, position of data.player_list
            players[id] = player = new Player
            player.position.components = position
            player_views[id] = player_view = new PlayerView
            player_view.model = player

        your_player = players[your_id]
        player = new PlayerView(your_player)
        setInterval (-> 
            for view in _.values player_views
                view.update()
                view.draw()
        ), 10

    join_template = """<form>Choose a name:<input type="text"><button>Join</button></form>"""
    page_template = """
        <div id="user-card"></div>
        <div id="game">
    """

    #render(join_template) 


    
