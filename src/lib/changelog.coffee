fs = require 'fs'
path = require 'path'
semver = require 'semver'

updateChangelog = (changelogFile, package, cb) ->

  changelog = fs.readFileSync(changelogFile, 'utf8')
  pkg = require package
  bumpAllComponents = undefined
  bumpCF = false

  # Grab the "Unreleased" section and split it by markdown h3's
  version = pkg.version.replace(/\./g, '\\.')
  unreleasedSection = changelog.match(new RegExp "(?=## Unreleased)([\\s\\S]+)(?=\n## #{version})", "igm")[0]
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
    componentName = "(\\*\\*(cf\\-[\\w\\-]+|all components|capital\\-framework):?\\*\\*)"
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
          bumpAllComponents = [bumpAllComponents, component.bump].sort().shift() if /^all/.test component.name
          bumpCF = true if /^capital-framework/.test component.name
          components[type].push(component)
    return components

  # Remove any empty types
  for type of types
    delete types[type] if types[type].length < 1

  # Abort if there's nothing to do
  return false if not Object.keys(types).length

  # First check if *only* capital-framework, and *no* components were updated
  bumpCF = do ->
    return bumpCF if not bumpCF
    nonCFBumps = 0
    cfBumpType = undefined
    for type of types
      # Sort the components alphabetically
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
    return fs.writeFileSync(package, JSON.stringify(pkg, null, 2));

  # Otherwise, bump the components mentioned in the changelog
  unreleased = ""
  for type of types
    heading = if types[type].length then "### #{type[0].toUpperCase() + type.slice 1}\n" else ""
    listItems = ""
    for component in types[type]
      listItems += "- **#{component.name}:** #{component.notes}\n"
      try
        # We're doing this ugly file reading instead of simply `require`ing because
        # the component manifests have a comment block that would get removed if we
        # `JSON.stringify`ed them.
        manifestFile = path.join(__dirname, 'src', component.name, 'package.json')
        manifest = fs.readFileSync manifestFile, 'utf8'
        bumpType = if bumpAllComponents then [bumpAllComponents, component.bump].sort().shift() else component.bump
        bump = semver.inc JSON.parse(manifest).version, bumpType
        manifest = manifest.replace /("version"\:\s*")[\d\.]+",/, '$1' + bump + '",'
        fs.writeFileSync manifestFile, manifest
      catch e
    unreleased += "#{heading}#{listItems}"
    # Add a line break if it's not the last section
    unreleased += "\n" if type != Object.keys(types)[Object.keys(types).length - 1]

  changelog = changelog.replace unreleasedSection, "## Unreleased\n\n#{unreleased}\n"
  fs.writeFileSync changelogFile, changelog
  cb null, types

module.export = updateChangelog
