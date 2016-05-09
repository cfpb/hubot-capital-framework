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

  describe 'capital framework plugin', ->
    it 'can be imported without blowing up', () ->
      cf = require('../src/capital-framework')(robot)
      expect(()->cf).to.not.throw()
