tmp = require 'tmp'
{exec} = require 'child_process'
icons = require './icons'
changelog = require './changelog'

token = process.env.HUBOT_GITHUB_ORG_TOKEN
cf = "https://github.com/cfpb/capital-framework.git"
branch = "release#{Date.now()}"

init = (res, cb) ->
  tmp.dir {unsafeCleanup: true}, (err, path, cleanup) ->
    return res.send "#{icons.failure} #{err}" if err
    res.send "#{icons.wait} Cloning Capital Framework's `canary` branch..."
    exec "git clone #{cf} .", {cwd: path}, (err) ->
      return res.send "#{icons.failure} #{err}" if err
      res.send "#{icons.wait} Updating Capital Framework's changelog..."
      exec "git clone #{cf} .", {cwd: path}, (err) ->
        return res.send "#{icons.failure} #{err}" if err
        res.send "#{icons.wait} Updating Capital Framework's changelog..."
        changelog path.join(__dirname, 'CHANGELOG.md'), path.join(__dirname, 'package.json'), (err, changes) ->
          console.log changes
          exec 'git commit -am "Preparing release"', {cwd: path}, (err) ->
            return res.send "#{icons.failure} #{err}" if err
            exec "git push https://#{token}:x-oauth-basic@github.com/contolini/capital-framework.git canary", {cwd: path}, (err, stdout, stderr) ->
              return res.send "#{icons.failure} #{err}" if err
              cb null, stdout or stderr
              cleanup()

module.exports = init
