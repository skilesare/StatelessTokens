
class PatriciaTree
  constructor: ()->
    @web3Utils = require('web3-utils')
    @root = null
    @items = []
    @lookUps = {}
  addItem: (key, value)=>
    #adds and updates items in our collection
    @lookUps[key] = [key, value]
    for thisItem in @items
      if thisItem[0] is key
        thisItem[1] = value
        return
    @items.push [key, value]
  bin2hex: (b) ->
    #utility function to translate binary to hex
    b.match(/.{4}/g).reduce ((acc, i) ->
      acc + parseInt(i, 2).toString(16)
    ), ''
  getProof: (key)=>
    #calculates a proof for a given key
    proof = []
    thisHash = null
    if !@lookUps[key]?
      #if we don't have an item then its value is 0
      proof.push key
      proof.push "0x0000000000000000000000000000000000000000000000000000000000000000"
    else
      #item 0 = key
      #item 1 = value
      proof.push @lookUps[key][0]
      proof.push @lookUps[key][1]
      thisHash = @web3Utils.soliditySha3(proof[0],proof[1])

    #place holders for our value map
    proof.push("")
    proof.push("")
    proof.push("")
    proof.push("")

    mapString = ""

    #trim off the 0x
    thisPath = key.slice(2)

    while thisPath.length > 0
      #loop until we get to the top
      thisPath = thisPath.substring(0,thisPath.length - 1)

      if thisPath.length == 0
        #we are at the top, use a special placeholder
        thisPath = "_"

      foundPath = @lookUps[thisPath]

      mapSubString = ""
      if foundPath?
        if @isPathSingular(thisPath) && thisHash isnt null
          # if the path is singular and we don't currently have a hash, our map can be all zeros for this set of 16
          mapSubString = mapSubString + "0000000000000000"
        else
          for thisItem in foundPath
            #loop through each item in this path

            if thisItem?
              #if the item exists we need to put a 1 in our binary map
              mapSubString = mapSubString + "1"
              if thisItem isnt thisHash
                #push the item onto the proof
                proof.push thisItem
            else
              #if the item doesn't exist we need to put a 0 on our binary map
              mapSubString = mapSubString + "0"
          #calculate the hash of this layer
          thisHash = @calcPathHash(thisPath)
      else
        #if the path doesn't exist we can spit out 0 and use our current hash
        mapSubString = mapSubString + "0000000000000000"
      if thisPath is "_"
        thisPath = ''

      mapString = mapString + mapSubString

    #convert the binary to hex
    bigHex = @bin2hex(mapString)

    #split the hex up
    proof[2] = "0x" + bigHex.substring(0, 64)
    proof[3] = "0x" + bigHex.substring(64, 128)
    proof[4] = "0x" + bigHex.substring(128, 192)
    proof[5] = "0x" + bigHex.substring(192, 256)
    return proof
  seedPath: (hash, location)=>
    #creates a 16 length bytes32 array with our current hash in the location it should be in
    resultMap = []
    for thisPos in [0...16]
      if parseInt(location,16) == thisPos
        resultMap.push hash
      else
        resultMap.push null
    return resultMap
  isPathSingular: (path)=>
    #determines if the current path has 0 or 1 items in it
    thisPath = @lookUps[path]
    count = 0
    for thisItem in thisPath
      if thisItem?
        count = count + 1
        if count > 1
          return false
    return true
  calcPathHash: (path)=>
    #calculates the hash of a path
    emptyItem =
        t:"bytes"
        v:"0x0000000000000000000000000000000000000000000000000000000000000000"
    foundPath = @lookUps[path]
    newHash = @web3Utils.soliditySha3(
      if !foundPath[0]? then emptyItem else {t:"bytes", v:foundPath[0]}
      if !foundPath[1]? then emptyItem else {t:"bytes", v:foundPath[1]}
      if !foundPath[2]? then emptyItem else {t:"bytes", v:foundPath[2]}
      if !foundPath[3]? then emptyItem else {t:"bytes", v:foundPath[3]}
      if !foundPath[4]? then emptyItem else {t:"bytes", v:foundPath[4]}
      if !foundPath[5]? then emptyItem else {t:"bytes", v:foundPath[5]}
      if !foundPath[6]? then emptyItem else {t:"bytes", v:foundPath[6]}
      if !foundPath[7]? then emptyItem else {t:"bytes", v:foundPath[7]}
      if !foundPath[8]? then emptyItem else {t:"bytes", v:foundPath[8]}
      if !foundPath[9]? then emptyItem else {t:"bytes", v:foundPath[9]}
      if !foundPath[10]? then emptyItem else {t:"bytes", v:foundPath[10]}
      if !foundPath[11]? then emptyItem else {t:"bytes", v:foundPath[11]}
      if !foundPath[12]? then emptyItem else {t:"bytes", v:foundPath[12]}
      if !foundPath[13]? then emptyItem else {t:"bytes", v:foundPath[13]}
      if !foundPath[14]? then emptyItem else {t:"bytes", v:foundPath[14]}
      if !foundPath[15]? then emptyItem else {t:"bytes", v:foundPath[15]})
    return newHash
  update: (path, location, hash)=>
    #updates the layer of a path
    thisPath = @lookUps[path]
    if !thisPath?
      #this path doesn't exist so seed it
      thisPath = @seedPath(hash, location)
      if thisPath.length > 16
        throw new error(location)
      @lookUps[path] = thisPath
    else
      #update this path with the hash at the given location
      @lookUps[path][parseInt(location, 16)] = hash
    newHash = hash

    if @isPathSingular(path)
      #if the path is singulare we can just pass our existing has up a layer
      if path isnt "_"
        newPath = path.substring(0,path.length - 1)
        if newPath.length == 0
          newPath = "_"
        #recursively call
        newHash = @update(newPath, path.substring(path.length - 1), hash)
      else
        #we found our root
        @root = newHash
    else
      #update the hash value
      emptyItem =
        t:"bytes"
        v:"0x0000000000000000000000000000000000000000000000000000000000000000"

      newHash = @calcPathHash(path)
      if path isnt "_"
        #recursively call
        newPath = path.substring(0,path.length - 1)
        if newPath.length == 0
          newPath = "_"
        newHash = @update(newPath, path.substring(path.length - 1), newHash)
      else
        #we found our root
        @root = newHash
    return newHash
  buildTree: ()=>
    for thisItem in @items
      #loop through each item in our collection and calculate the root
      thisHash = @web3Utils.soliditySha3({t:"bytes",v:thisItem[0].slice(2)},{t:"bytes",v:thisItem[1].slice(2)})
      thisPath = thisItem[0].slice(2)
      aByte = thisPath[thisPath.length - 1]
      findPath = thisPath.substring(0, thisPath.length - 1)
      @root = @update(findPath, aByte, thisHash)
    return

exports.PatriciaTree = PatriciaTree