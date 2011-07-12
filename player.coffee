define [
    'cs!library/vector'
], (Vector) ->

    class Player
        constructor: ->
            @position = new Vector(50,50)

