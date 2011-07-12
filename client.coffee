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
            @model.position = @model.position.add motion.scale(speed)
            #socket.emit 'move', position:@model.position
            
        draw: ->
            @el.css @model.position.as_css()

    player = new PlayerView(new Player())
    setInterval (-> 
        player.update()
        player.draw()
    ), 10


    join_template = """<form>Choose a name:<input type="text"><button>Join</button></form>"""
    page_template = """
        <div id="user-card"></div>
        <div id="game">
    """

    #render(join_template) 


    
