Chaplin = require 'chaplin'

Mediator = require 'chaplin/core/Mediator'

ListCollection = require 'chaplin/models/ListCollection'
List = require 'chaplin/models/List'
ListObjectCollection = require 'chaplin/models/ListObjectCollection'
FolderCollection = require 'chaplin/models/FolderCollection'
Path = require 'chaplin/models/Path'

# A flat store of all lists (and folders) on a page.
module.exports = class Store extends Chaplin.Collection

    # A first class object, Folders and Tags are 'niceties'.
    model: List

    # Point-less reference just to remember it will be present.
    folders: null

    initialize: ->
        # Hold folders here and re-initialize.
        @folders = new FolderCollection()

        # Listen to others telling us to deselect all lists.
        Mediator.subscribe 'deselectAll', @deselectAll, @

    # Our custom constructor.
    # Alternatively, we could let Backbone init Lists and then retrospectively create Folders and add Obj.
    constructor: ->
        # Backbone.js
        @_reset()
        @initialize.apply this, arguments

        # Our stuff.
        for row in ListCollection
            @makeFolder @makeList row

    # We will never really go away...
    dispose: ->

    # Deselect all lists held, silently...
    deselectAll: ->
        list.set('checked': false, { 'silent': true }) for list in @.where('checked': true)

        # Say that 0 many lists are selected.
        Mediator.publish 'checkedLists', 0

    ###
    Find a list from this collection by its slug.
    @param {string} slug
    ###
    findList: (slug) ->
        l = @filter (item) -> item.get('slug') is slug
        if l.length > 0
            l[0]

    ###
    Make a list out if dict data.
    @param {Object} data A pure dictionary of data to make into a List object.
    ###
    makeList: (data) ->
        # Slugify the path.
        data.path = ( part.latinise().slugify() for part in data.path.split('/') ).join('/')

        # Slugify the list name.
        data.slug = data.name.latinise().slugify()

        # Set all lists as not checked in the UI by default.
        data.checked = false
        
        # Get the list objects.
        data.objects = new ListObjectCollection()

        # Create us and return us.
        @.push data, 'silent': true
        @.at(@.length - 1)

    ###
    Given a key find the one matching folder.
    @param {string} key
    @param {string} param An attribute to filter by
    ###
    findFolder: (path, param='path') ->
        f = @folders.filter (item) -> item.get(param) is path
        if f.length > 0
            f[0]

    ###
    For a given path will (create folder and) link to list (and parent folder) (and back...).
    @param {List} list
    ###
    makeFolder: (list) ->
        path = list.get('path')

        # Find in existing.
        folder = @findFolder path
        if folder?
            # Append the list reference.
            folder.addList list
        
        else
            # No cigar... add a new one linking to this list.
            @folders.push
                'path':    path
                'name':    path.split('/').pop().replace(/\-/g, ' ') # last part of the path.
                'lists':   [ list ]
                'folders': []
                'slug':    path[1...] # the path except the leading forward slash
                'active':  false

            # Get the added folder.
            folder = @folders.at(@folders.length - 1)
            # Make a back-reference to this folder from the list.
            list.set 'folder': folder
            
            # Do we need to link this folder to a parent folder?
            parentPath = (p = path.split('/'))[0...p.length - 1].join('/')
            # Linked to root folder including root folder itself.
            if parentPath is '' and path isnt '/' then parentPath = '/'
            if parentPath isnt ''
                # Does the parent exist already?
                parent = @findFolder parentPath
                if parent?
                    # Link us.
                    folders = parent.get('folders')
                    folders.push folder
                    parent.unset 'folders', 'silent': true
                    parent.set 'folders': folders
                
                else
                    # Create a new folder and link to this folder.
                    @folders.push
                        'path':    parentPath
                        'name':    parentPath.split('/').pop().replace(/\-/g, ' ') # last part of the path.
                        'lists':   []
                        'folders': [ folder ]
                        'slug':    parentPath[1...] # the path except the leading forward slash
                        'active':  false

                    parent = @folders.at(@folders.length - 1)

                # Make a back reference to the parent.
                folder.set 'parent': parent

    ###
    Expand a given path and any folders leading up to it.
    @param {string or Folder} obj A list path or a Folder object (not its parent)
    ###
    expandFolder: (obj) ->
        if obj.constructor.name isnt 'Folder'
            # Get the initial folder by path.
            folder = @findFolder obj
        else
            # Get the parent of this folder.
            folder = obj.get 'parent'

        # Traverse the tree up and set the parents to be expanded too.
        while folder?
            folder.set 'expanded': true
            folder = folder.get 'parent'

    ###
    Will select this folder and deselect all others.
    @param {Folder} folder A folder to select
    ###
    activeFolder: (folder) ->
        # Deselect all others.
        f.set('active', false) for f in @folders.models

        # Select this one.
        folder.set 'active', true

    ###
    Give us a Collection representation of the path.
    @param {List or Folder} obj
    ###
    getPath: (obj) ->
        coll = new Path()
        
        if obj.constructor.name is 'List'
            coll.addList obj
            folder = @findFolder obj.get 'path'
        else
            folder = obj
        
        # Traverse the tree up.
        while folder?
            coll.addFolder folder
            folder = folder.get 'parent'

        coll

    # Get the folder that is set to be selected or return root.
    getActiveFolder: ->
        for folder in @folders.models
            if folder.get('active') is true
                return folder
        # Catch all return root.
        return @findFolder '/'