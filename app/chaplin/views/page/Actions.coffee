Chaplin = require 'chaplin'

Mediator = require 'chaplin/core/Mediator'
View = require 'chaplin/core/View'
Garbage = require 'chaplin/core/Garbage'

NewFolderView = require 'chaplin/views/page/NewFolder'
OrganiseListsView = require 'chaplin/views/page/OrganiseLists'

module.exports = class ActionsView extends View

    container:  '#actions'
    autoRender: true

    # Number of checked lists.
    checked: 0

    # The currently active folder.
    folder: undefined

    # Link to main Store.
    store: null

    # Which buttons to show?
    show:
        'newFolder':     true # create a new folder
        'organiseLists': true # organise lists into a folder

    getTemplateFunction: -> require 'chaplin/templates/actions'

    getTemplateData: ->
        'checked': @checked
        'show':    @show # the permissions for buttons...

    initialize: ->
        super

        @views = new Garbage()

        # Main Store.
        @store = window.Store

        # Listen to lists being checked or completely unchecked.
        Mediator.subscribe 'checkedLists', (@checked) => @render()
        Mediator.subscribe 'deselectAll', @uncheckAll, @

        # Listen to the current active folder.
        Mediator.subscribe 'activeFolder', (@folder) =>

        # Listen to page layouts.
        Mediator.subscribe 'page', @change, @

        # Events.
        @delegate 'click', 'a.new-folder', @newFolder
        @delegate 'click', 'a.organise',   @organise

    # Depending on the page layout now active, render us.
    change: (page) ->
        switch page
            # 404 on a folder or a list.
            when '404'
                @show.newFolder =     false
                @show.organiseLists = false
            # List objects.
            when 'list'
                @show.newFolder =     false
                @show.organiseLists = false
            # Folder holder.
            when 'folder'
                @show.newFolder =     true
                @show.organiseLists = true
            # Filter lists.
            when 'filter'
                @show.newFolder =     false
                @show.organiseLists = true

        #console.log JSON.stringify @show

        # Apply apply...
        @render()

    # Set all list to not be checked at all.
    uncheckAll: ->
        @checked = 0
        @render()

    newFolder: =>
        # Create a popover View to handle the interaction.
        @views.push new NewFolderView 'model': @folder

    organise: =>
        # Create a popover View to handle the interaction.
        # Pass in a Collection of selected lists.
        @views.push new OrganiseListsView
            'collection': new Chaplin.Collection @store.where('checked': true)
            'model': @folder