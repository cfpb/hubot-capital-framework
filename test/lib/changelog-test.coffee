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
temp = {}

changelogTest = (name, done) ->
  changelogLoc = path.join __dirname, "..", "fixtures", "changelog-#{name}.md"
  changelogLocExpected = path.join __dirname, "..", "fixtures", "changelog-#{name}_expected.md"
  packageLoc = path.join __dirname, "..", "fixtures", "package.json"
  tmpPackageLoc = path.join temp.base, "package.json"
  tmpChangelogLoc = path.join temp.base, "changelog-#{name}.md"
  fs.copySync changelogLoc, tmpChangelogLoc
  fs.copySync packageLoc, tmpPackageLoc
  packageLoc = path.join __dirname, "..", "fixtures", "package.json"
  changelog temp.test, tmpChangelogLoc, tmpPackageLoc, (err, changes) ->
    before = fs.readFileSync tmpChangelogLoc, "utf8"
    after = fs.readFileSync changelogLocExpected, "utf8"
    fs.readdirSync(path.join(temp.test, 'src')).forEach (c) ->
      if /^cf-/.test c
        loc = path.join(temp.test, 'src', c, 'package.json')
        version = require(loc).version
        # Ensure each version is non-null
        # console.log require(loc).name, version
        expect(semver.valid(version)).to.be.ok
    expect(after).to.equal(before)
    do done

describe 'capital-framework changelog', ->
  @timeout 20000

  before (done) ->
    tmp.dir {mode: '777', unsafeCleanup: false}, (err, tmpath, cleanup) ->
      temp.base = path.join tmpath
      temp.repo = path.join tmpath, 'repo'
      temp.test = path.join tmpath, 'test'
      fs.ensureDirSync temp.repo
      fs.ensureDirSync temp.test
      exec "git clone #{cf} .", {cwd: temp.repo}, (err) ->
        return console.error err if err
        do done

  beforeEach (done) ->
    rimraf.sync temp.test
    fs.copy temp.repo, temp.test, {clobber: true}, done

  describe 'changelog helper', ->

    it 'processes a simple changelog', (done) ->
      changelogTest 'simple', done

    it 'processes a broken changelog', (done) ->
      changelogTest 'broken', done

    it 'processes a complex changelog', (done) ->
      changelogTest 'complex', done

    it 'processes a changelog of only "all components"', (done) ->
      changelogTest 'all', done

    it 'processes a complex changelog including "all components"', (done) ->
      changelogTest 'all-complex', done

    it 'processes a changelog with duplicate fixes', (done) ->
      changelogTest 'duplicate', done

    it 'processes a changelog of only "capital-framework"', (done) ->
      changelogTest 'cf', done

    it 'processes a changelog even if the markdown is a little weird', (done) ->
      changelogTest 'colon', done
