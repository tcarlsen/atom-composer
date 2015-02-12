{CompositeDisposable} = require 'atom'
{LineStream} = require 'byline'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'
{spawn} = require 'child_process'
strs = require 'stringstream'

module.exports = Composer =
  config:
    composerPath:
      default: '/usr/local/bin/composer'
      title: 'Path to composer executable'
      type: 'string'

  composerView: null
  subscriptions: null

  activate: (state) ->
    @composerView = new MessagePanelView
      title: 'Composer'

    # Events subscribed to in atom's system can be easily cleaned up with a
    # CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Define commands
    commands = [
      'composer:about': => @composer 'about'
    ,
      'composer:archive': => @composer 'archive'
    ,
      'composer:clear-cache': => @composer 'clear-cache'
    ,
      'composer:dump-autoload': => @composer 'dump-autoload'
    ,
      'composer:install': => @composer 'install'
    ,
      'composer:self-update': => @composer 'self-update'
    ,
      'composer:update': => @composer 'update'
    ,
      'composer:validate': => @composer 'validate'
    ,
      'composer:version': => @composer '-V'
    ]

    # Register commands
    for command in commands
      @subscriptions.add atom.commands.add 'atom-workspace', command

  deactivate: ->
    @subscriptions.dispose()
    @composerView.destroy()

  composer: (command) ->
    closeOnComplete = atom.config.get 'composer.closeOnComplete'
    composerPath = atom.config.get 'composer.composerPath'
    firstRun = true
    [projectPath, ...] = atom.project.getPaths()

    childProcess = spawn composerPath, [command, '-d', projectPath]
    stdout = childProcess.stdout
    stderr = childProcess.stderr

    stdout.pipe new LineStream
      .pipe strs 'utf8'
      .on 'data', (data) =>
        if firstRun
          @composerView.clear()
          firstRun = false

        @composerView.attach()

        if ~data.indexOf 'Downloading:'
          [message,...] = @composerView.messages
          @composerView.clear()
          @composerView.add message

        @composerView.add new PlainMessageView
          message: data

    stderr.pipe new LineStream
      .pipe strs 'utf8'
      .on 'data', (data) ->
        console.error data
