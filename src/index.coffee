{Adapter, TextMessage, User} = require "hubot"
TelegramBot = require 'telegram-bot'

class TelegramAdapter extends Adapter
  constructor: ->
    unless process.env.HUBOT_TELEGRAM_BOT_TOKEN
      throw Error 'Configuration HUBOT_TELEGRAM_BOT_TOKEN is required'

    super

  send: (envelope, strings...) ->
    @_debugLog 'send', envelope, strings...
    {user, room} = envelope
    user = envelope unless user
    strings.forEach (str) =>
      @tg.sendMessage chat_id: (room.id or user.id), text: str

  reply: (envelope, strings...) ->
    user = if envelope.user then envelope.user else envelope
    strings.forEach (str) =>
      @send envelope, "@#{user.name} #{str}"

  run: ->
    @tg = new TelegramBot process.env.HUBOT_TELEGRAM_BOT_TOKEN

    @tg.on 'connected', (botInfo) =>
      @_debugLog 'connected'
      @emit 'connected'

    @tg.on 'message', (msg) =>
      @_debugLog 'new message', msg
      @robot.receive @_transformMessage msg

    @tg.start()

  _debugLog: (messages...) ->
    @robot.logger.debug '[Telegram Adapter]', messages...

  _transformUser: (userInfo, group) ->
    new User userInfo.id, name: userInfo.username, room: {id: group.id, title: group.title}

  _transformMessage: (messageInfo) ->
    new TextMessage @_transformUser(messageInfo.from, messageInfo.chat), messageInfo.text, messageInfo.message_id

exports.use = (robot) ->
  new TelegramAdapter robot
