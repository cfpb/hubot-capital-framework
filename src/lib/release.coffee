tmp = require 'tmp'
{exec} = require 'child_process'
path = require 'path'
icons = require './icons'
changelog = require './changelog'
pr = require './pull-request'

tmp.setGracefulCleanup()

token = process.env.HUBOT_GITHUB_CF_TOKEN
cf = "https://github.com/cfpb/capital-framework.git"
branch = "release#{Date.now()}"

init = (res, cb) ->
  tmp.dir {unsafeCleanup: true}, (err, tmpath) ->
    console.log tmpath
    return res.send "#{icons.failure} #{err.split('\n')[0]}" if err
    res.send "#{icons.wait} Cloning Capital Framework's `canary` branch..."
    exec "git clone #{cf} .", {cwd: tmpath}, (err) ->
      return res.send "#{icons.failure} #{err.split('\n')[0]}" if err
      res.send "#{icons.wait} Updating Capital Framework's changelog..."
      changelogLoc = path.join(tmpath, 'CHANGELOG.md')
      packageLoc = path.join(tmpath, 'package.json')
      changelog tmpath, changelogLoc, packageLoc, (err, changes, changesPreview) ->
        return res.send "#{icons.failure} #{err.split('\n')[0]}" if err
        setTimeout ->
          res.send "#{icons.wait} Running `npm install` to update the lockfile. This could take a few minutes..."
        , 1000
        exec 'npm install', {cwd: tmpath}, (err) ->
          return res.send "#{icons.failure} #{err.split('\n')[0]}" if err
          exec 'git commit -am "Preparing release"', {cwd: tmpath}, (err) ->
            return cb err if err
            branch = "release#{Date.now()}"
            exec "git checkout -b #{branch}", {cwd: tmpath}, (err) ->
              return cb err if err
              exec "git push https://#{token}:x-oauth-basic@github.com/cfpb/capital-framework.git #{branch}", {cwd: tmpath}, (err, stdout, stderr) ->
                return cb err if err
                pr token, branch, changesPreview, (err, data) ->
                  return cb err if err
                  username = res.envelope.user.name or 'Success!'
                  cb null, "#{username} Here's the release PR: #{data.html_url}. Please verify its accuracy and merge away."

module.exports = init
