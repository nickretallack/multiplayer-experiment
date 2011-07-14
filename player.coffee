define [
    'cs!library/vector'
    'cs!library/keydown'
], (Vector, KEYS) ->


    class Player
        constructor: ->
            @position = new Vector(50,50)
            @radius = 25

