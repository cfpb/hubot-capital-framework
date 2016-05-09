chai = require 'chai'
sinon = require 'sinon'
_ = require 'lodash'
expect = chai.expect
helper = require 'hubot-mock-adapter-helper'
TextMessage = require('hubot/src/message').TextMessage

chai.use require 'sinon-chai'

class Helper
  constructor: (@robot, @adapter, @user)->

  sendMessage: (done, message, callback)->
    if typeof done == 'string'
      callback = message or ->
      message = done
      done = ->
    @sendMessageHubot(@user, message, callback, done, 'send')

  replyMessage: (done, message, callback)->
    if typeof done == 'string'
      callback = message
      message = done
      done = ->
    @sendMessageHubot(@user, message, callback, done, 'reply')

  sendMessageHubot: (user, message, callback, done, event) ->
    done = _.once done
    @adapter.on event, (envelop, string) ->
      try
        callback(string)
        done()
      catch e
        done e
    @adapter.receive new TextMessage(user, message)

describe 'capital-framework', ->
  {robot, user, adapter} = {}
  messageHelper = null

  beforeEach (done)->
    helper.setupRobot (ret) ->
      process.setMaxListeners(0)
      {robot, user, adapter} = ret
      messageHelper = new Helper(robot, adapter, user)
      process.env.HUBOT_AUTH_ADMIN = user['id']
      messageHelper.robot.auth = isAdmin: ->
        return process.env.HUBOT_AUTH_ADMIN.split(',').indexOf(user['id']) > -1
      do done

  afterEach ->
    robot.shutdown()

  beforeEach ->
    require('../src/capital-framework')(robot)

  describe 'really cool feature', ->
    it 'greets you back', (done)->
      # If the bot is `reply`ing to the user, use `replyMessage`
      messageHelper.replyMessage done, 'hubot hello', (result) ->
        expect(result[0]).to.equal('hello!')

  describe 'other really cool feature', ->
    # Otherwise, use `sendMessage`
    it "ignores you if you're not an admin", (done) ->
      process.env.HUBOT_AUTH_ADMIN = []
      messageHelper.sendMessage done, 'orly', (result) ->
        expect(result[0]).to.equal('Sorry, only admins can do that.')

    it "reponds if you're an admin", (done)->
      messageHelper.sendMessage done, 'orly', (result) ->
        expect(result[0]).to.equal('yarly')

  describe 'storage features', ->
    it "adds items", (done) ->
      messageHelper.sendMessage done, 'hubot add foo to the thing', (result) ->
        expect(result[0]).to.equal('Alright, I added foo to the thing.')

    it "removes items", (done) ->
      messageHelper.sendMessage done, 'hubot remove foo from the thing', (result) ->
        expect(result[0]).to.equal('Okay, I removed foo from the thing.')

    it "only lets admins remove items", (done) ->
      process.env.HUBOT_AUTH_ADMIN = []
      messageHelper.sendMessage done, 'hubot remove foo from the thing', (result) ->
        expect(result[0]).to.equal('Sorry, only admins can remove stuff.')
