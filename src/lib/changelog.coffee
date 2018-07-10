fs = require 'fs'
path = require 'path'
semver = require 'semver'
_ = require 'lodash'

updateChangelog = (tmpLocation, changelogLocation, packageLocation, cb) ->

  changelog = fs.readFileSync(changelogLocation, 'utf8')
  pkg = require packageLocation
  bumpAllComponents = {}
  bumpCF = false

  # Grab the "Unreleased" section and split it by markdown h3's
  version = pkg.version.replace(/\./g, '\\.')
  unreleasedSection = changelog.match(new RegExp "(?=## Unreleased)([\\s\\S]+?)(?=\n## [0-9]+?\.[0-9]+?\.[0-9]+?)", "igm")[0]
  lines = unreleasedSection.split('### ').filter((line) -> return line).slice(1)

  # Organize the unreleased changelog items by type ("added", "changed", or "removed")
  types = {}
  for line in lines
    type = line.split('\n')[0].toLowerCase()
    types[type] = line.split('\n- ').slice(1).filter (type) -> return type.length > 10

  # Standardize the types and their respective changelog notes
  types = do ->
    components = {}
    bumpType = "(\\[?(major|minor|patch)\\]?)"
    componentName = "(\\*\\*(cf\\-[\\w\\-]+|all components|capital\\-framework):?\\*\\*):?"
    notes = "([\\s\\S]+)"
    re = new RegExp "#{bumpType}?\\s?#{componentName}\\s+#{bumpType}?#{notes}", "i"
    for type of types
      components[type] = []
      for component in types[type]
        matches = component.match re
        if matches
          component =
            name: (matches[4]).toLowerCase()
            bump: (matches[2] or matches[6] or "").toLowerCase()
            notes: matches[7].trim()
          # If this is "all components", record the bump so we can bump all components later
          if /^all/.test component.name
            bumpAllComponents[type] =
              bump: [bumpAllComponents.bump, component.bump].sort().shift()
              notes: component.notes
          bumpCF = true if /^capital-framework/.test component.name
          components[type].push(component)
    return components

  # Remove any empty types
  for type of types
    delete types[type] if types[type].length < 1

  # Abort if there's nothing to do
  return cb "There's nothing to release!" if not Object.keys(types).length

  # First check if *only* capital-framework, and *no* components were updated
  bumpCF = do ->
    return bumpCF if not bumpCF and not Object.keys(bumpAllComponents).length
    nonCFBumps = 0
    cfBumpType = undefined
    for type of types
      # While we're in here, make a note to bump all components if necessary
      if bumpAllComponents[type]
        for component in fs.readdirSync path.join(tmpLocation, 'src')
          if /^cf-/.test component
            componentGettingBumped = _.findKey(types[type], (c) -> c.name is component)
            if componentGettingBumped != undefined
              types[type][componentGettingBumped].bump = [bumpAllComponents[type].bump, types[type][componentGettingBumped].bump].sort().shift()
            else
              types[type].push {
                name: component
                bump: bumpAllComponents[type].bump
                notes: bumpAllComponents[type].notes
                extraneous: true
              }
        # Also, sort the components alphabetically
        types[type] = types[type].sort (a, b) ->
          return if a.name < b.name then -1 else 1
      for component in types[type]
        if /^capital-framework/.test component.name
          cfBumpType = [cfBumpType, component.bump].sort().shift()
        else
          nonCFBumps++
    return if nonCFBumps < 1 then cfBumpType else false

  # If this is the case, bump CF and we're done
  if bumpCF
    pkg.version = semver.inc pkg.version, bumpCF
    unreleased = "Bump Capital Framework to #{pkg.version}. No components were updated."
    fs.writeFileSync(packageLocation, JSON.stringify(pkg, null, 2));

  # Otherwise, bump the components mentioned in the changelog
  componentsToBump = {}
  for type of types
    for component in types[type]
      if not componentsToBump[component.name]
        componentsToBump[component.name] = component.bump
      else
        componentsToBump[component.name] = [componentsToBump[component.name], component.bump].sort().shift()

  for component of componentsToBump
    try
      if componentsToBump[component]
        # We're doing this ugly file reading instead of simply `require`ing because
        # the component manifests have a comment block that would get removed if we
        # `JSON.stringify`ed them.
        manifestFile = path.join tmpLocation, 'src', component, 'package.json'
        manifest = fs.readFileSync manifestFile, 'utf8'
        bumpType = if bumpAllComponents.bump then [bumpAllComponents.bump, componentsToBump[component]].sort().shift() else componentsToBump[component]
        bump = semver.inc JSON.parse(manifest).version, bumpType
        manifest = manifest.replace /("version"\:\s*")[\d\.]+",/, '$1' + bump + '",'
        fs.writeFileSync manifestFile, manifest
    catch e

  unreleased = ""
  unreleasedPreview = ""
  for type of types
    heading = if types[type].length then "### #{type[0].toUpperCase() + type.slice 1}\n" else ""
    listItems = ""
    listItemsPreview = ""
    for component in types[type]
      listItems += "- **#{component.name}:** #{component.notes}\n" if not component.extraneous
      listItemsPreview += "- **#{component.name}:** [#{component.bump}] #{component.notes}\n" if not component.extraneous
    unreleased += "#{heading}#{listItems}"
    unreleasedPreview += "#{heading}#{listItemsPreview}"
    # Add a line break if it's not the last section
    unreleased += "\n" if type != Object.keys(types)[Object.keys(types).length - 1]
    unreleasedPreview += "\n" if type != Object.keys(types)[Object.keys(types).length - 1]

  changelog = changelog.replace unreleasedSection, "## Unreleased\n\n#{unreleased}\n"
  fs.writeFileSync changelogLocation, changelog
  cb null, unreleased, unreleasedPreview

module.exports = updateChangelog
