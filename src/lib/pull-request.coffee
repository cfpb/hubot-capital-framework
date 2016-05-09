github = require 'github'
github = new github version: "3.0.0", debug: false, headers: Accept: "application/vnd.github.moondragon+json"

pr = (token, branch, body, cb) ->
  github.authenticate type: "oauth", token: token
  greeting = "I am a [bot](https://github.com/cfpb/cfpbot). If I did something wrong, blame a human.\n\n![kitten gif](http://thecatapi.com/api/images/get?format=src&type=gif)"
  body = "#{body}\n\n## Review\n\n- @cfpb/front-end-team-admin\n\n#{greeting}"
  github.pullRequests.create user: 'cfpb', repo: 'capital-framework', title: 'CF Release', base: 'master', head: branch, body: body, (err, data) ->
    cb err if err
    cb null, data

module.exports = pr
