define [
    'chaplin'
    'views/notification'
    'templates/all'           # make all templates globally available
], (Chaplin, NotificationView) ->

    # Whole body experience.
    class Layout extends Chaplin.Layout

        initialize: ->
            super

            # App wide notification.
            Chaplin.mediator.subscribe 'notification', @notify

            # Our first message.
            Chaplin.mediator.publish 'notification', 'Welcome to InterMine'

        ###
        Create a new notification.
        @param {string} text Text of the notification message.
        @param {string} title Text of the notification message title, not required.
        @param {string} type Type of the message, determines CSS class (notify/warn/error)
        @param {boolean} sticky Close automagically or stick around?
        ###
        notify: (text, title, type='notify', sticky=false) ->
            new NotificationView text, title, type, sticky