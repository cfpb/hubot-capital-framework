chai = require 'chai'
sinon = require 'sinon'
tmp = require 'tmp'
{exec} = require 'child_process'
path = require 'path'
rimraf = require 'rimraf'
fs = require 'fs-extra'
semver = require 'semver'
expect = chai.expect

chai.use require 'sinon-chai'

changelog = require '../../src/lib/changelog'
cf = 'https://github.com/cfpb/capital-framework.git'
tag = '5.0.0' # snapshot of repo to use for testing purposes
temp = {}

changelogTest = ( name, componentsToVerify, done ) ->
  changelogLoc = path.join __dirname, "..", "fixtures", "changelog-#{name}.md"
  changelogLocExpected = path.join __dirname, "..", "fixtures", "changelog-#{name}_expected.md"
  packageLoc = path.join __dirname, "..", "fixtures", "package.json"
  tmpPackageLoc = path.join temp.base, "package.json"
  tmpChangelogLoc = path.join temp.base, "changelog-#{name}.md"
  fs.copySync changelogLoc, tmpChangelogLoc
  fs.copySync packageLoc, tmpPackageLoc
  packageLoc = path.join __dirname, "..", "fixtures", "package.json"
  changelog temp.currentTest, tmpChangelogLoc, tmpPackageLoc, (err, changes) ->
    before = fs.readFileSync tmpChangelogLoc, "utf8"
    after = fs.readFileSync changelogLocExpected, "utf8"
    fs.readdirSync(path.join(temp.currentTest, 'src')).forEach (c) ->
      if /^cf-/.test c
        loc = path.join(temp.currentTest, 'src', c, 'package.json')
        expectedVersion = componentsToVerify[require(loc).name];
        version = require(loc).version
        # If Individual components' versions were provided, check them.
        if semver.valid expectedVersion
          expect(require(loc).version).to.equal(expectedVersion)
        # Ensure each version is non-null
        expect(semver.valid(version)).to.be.ok
    expect(after).to.equal(before)
    do done

n = 0
genTestDir = (dir) ->
  return dir + ++n

describe 'capital-framework changelog', ->
  @timeout 60000

  describe 'changelog helper', ->

    before (done) ->
      tmp.dir {mode: '777', unsafeCleanup: false}, (err, tmpath, cleanup) ->
        temp.base = path.join tmpath
        temp.repo = path.join tmpath, 'repo'
        temp.test = path.join tmpath, 'test'
        fs.ensureDirSync temp.repo
        exec "git clone -b '#{tag}' --single-branch --depth 1 #{cf} .", {cwd: temp.repo}, (err) ->
          return console.error err if err
          do done

    beforeEach (done) ->
      temp.currentTest = genTestDir temp.test
      fs.copy temp.repo, temp.currentTest, {clobber: true}, done

    after (done) ->
      rimraf.sync temp.base
      do done

    it 'processes a simple changelog', (done) ->
      changelogTest 'simple', {}, done

    it 'processes a broken changelog', (done) ->
      changelogTest 'broken', {}, done

    it 'processes a complex changelog', (done) ->
      changelogTest 'complex', {}, done

    it 'processes a changelog of only "all components"', (done) ->
      changelogTest 'all', {}, done

    it 'processes a complex changelog including "all components"', (done) ->
      changelogTest 'all-complex', {}, done

    it 'processes a changelog with duplicate fixes', (done) ->
      changelogTest 'duplicate', {}, done

    it 'processes a changelog of only "capital-framework"', (done) ->
      changelogTest 'cf', {}, done

    it 'processes a changelog even if the markdown is a little weird', (done) ->
      changelogTest 'colon', {}, done

    it 'processes a changelog that has a minor bump before a patch bump', (done) ->
      changelogTest 'minorpatch', { 'cf-forms': '5.1.0' }, done
