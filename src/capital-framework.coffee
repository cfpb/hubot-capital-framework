# Description
#   A Hubot script to manage CFPB's Capital Framework
#
# Configuration:
#   HUBOT_GITHUB_ORG_TOKEN - (required) Github access token that can access cfpb/capital-framework. See https://help.github.com/articles/creating-an-access-token-for-command-line-use/.
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Chris Contolini

release = require './lib/release'

# class CapitalFrameworkRobot
#   constructor: (@robot) ->
#     @config = process.env.HUBOT_CAPITALFRAMEWORK_SETTING or 'whatever the default value should be'
#     capitalFramework = @robot.brain.get 'capitalFramework'
#     @capitalFramework = capitalFramework or []
#     @robot.brain.set 'capitalFramework', @capitalFramework
#   add: (item) ->
#     @capitalFramework.push item
#     @robot.brain.set 'capitalFramework', @capitalFramework
#   remove: (item) ->
#     @capitalFramework = @capitalFramework.filter (i) -> i isnt item
#     @robot.brain.set 'capitalFramework', @capitalFramework

module.exports = (robot) ->
  # capitalFrameworkRobot = new CapitalFrameworkRobot robot

  robot.respond /cf (prepare )?release/, (res) ->
    release res, (err, msg) ->
      return res.send "#{icons.failure} #{err}" if err
      res.send "#{msg}"

  # robot.respond /add (\S*) to the thing/, (msg) ->
  #   item = msg.match[1]
  #   capitalFrameworkRobot.add(item)
  #   msg.send "Alright, I added #{item} to the thing."
  #
  # robot.respond /remove (\S*) from the thing/, (msg) ->
  #   item = msg.match[1]
  #   if robot.auth.isAdmin msg.envelope.user
  #     capitalFrameworkRobot.remove(item)
  #     message = "Okay, I removed #{item} from the thing."
  #   else
  #     message = "Sorry, only admins can remove stuff."
  #   msg.send message
