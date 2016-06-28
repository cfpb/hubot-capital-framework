chai = require 'chai'
sinon = require 'sinon'
tmp = require 'tmp'
{exec} = require 'child_process'
path = require 'path'
fs = require 'fs-extra'
expect = chai.expect

chai.use require 'sinon-chai'

changelog = require '../../src/lib/changelog'
cf = 'https://github.com/cfpb/capital-framework.git'

describe 'capital-framework', ->
  {robot, user, adapter} = {}
  messageHelper = null

  beforeEach (done) ->
    do done

  describe 'changelog helper', ->

    it 'processes a complex changelog', (done) ->
      @timeout 20000
      tmp.dir {mode: '777', unsafeCleanup: true}, (err, tmpath, cleanup) ->
        exec "git clone #{cf} .", {cwd: tmpath}, (err) ->
          changelogLoc = path.join __dirname, '..', 'fixtures', 'changelog-complex.md'
          changelogLocExpected = path.join __dirname, '..', 'fixtures', 'changelog-complex_expected.md'
          tmpChangelogLoc = path.join tmpath, 'changelog-complex.md'
          fs.copySync(changelogLoc, tmpChangelogLoc);
          packageLoc = path.join __dirname, '..', 'fixtures', 'package.json'
          changelog tmpath, tmpChangelogLoc, packageLoc, (err, changes) ->
            before = fs.readFileSync tmpChangelogLoc, 'utf8'
            after = fs.readFileSync changelogLocExpected, 'utf8'
            expect(after).to.equal(before)
            do done
