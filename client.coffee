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
        control: ->
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

    make_a_player = (id, position) ->
        players[id] = player = new Player
        player.position.components = position
        player_views[id] = player_view = new PlayerView
        player_view.model = player

    socket.on 'player-list', (data) ->
        your_id = data.your_id
        for id, position of data.player_list
            make_a_player id, position

        setInterval (-> 
            player_views[your_id].control()
            for view in _.values player_views
                view.draw()
        ), 10

    socket.on 'joined', (data) ->
        unless data.player_id is your_id
            make_a_player data.player_id, data.position

    join_template = """<form>Choose a name:<input type="text"><button>Join</button></form>"""
    page_template = """
        <div id="user-card"></div>
        <div id="game">
    """

    #render(join_template) 


    
