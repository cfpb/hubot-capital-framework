# Description
#   A Hubot script to manage CFPB's Capital Framework
#
# Configuration:
#   HUBOT_GITHUB_CF_TOKEN - (required) Github access token that can access cfpb/capital-framework. See https://help.github.com/articles/creating-an-access-token-for-command-line-use/.
#
# Commands:
#   hubot capital framework release - Create a Capital Framework release PR
#
# Author:
#   contolini

release = require './lib/release'
icons = require './lib/icons'

module.exports = (robot) ->

  robot.respond /(capital[-\s]?framework|cf) (prepare )?release/, (res) ->
    release res, (err, msg) ->
      return res.send "#{icons.failure} #{err}" if err
      res.send "#{icons.success} #{msg}"
