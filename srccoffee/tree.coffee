
class Tree
  constructor: ()->
    @web3Utils = require('web3-utils')
    @root = null
    @layers = []
    @layers.push([])
  addItem: (key, value)=>
    @layers[0].push [key, value]
  getProof: (key)=>
    map = []
    seek = key
    # 'looking for ' + key
    # to produce a proof we look through each layer from bottom to top looking for first the
    # passed in key and then the hash combination
    for thisLayer in [0...@layers.length]
      # 'seeking layer '+ thisLayer
      for thisItem in [0...@layers[thisLayer].length]
        # 'inspecting:' + thisItem
        # console.log @layers[thisLayer][thisItem]
        # The found item will be either on the left or right hand side
        if @layers[thisLayer][thisItem][0] is seek
          # console.log 'found seek in position 0'
          # push the item onto the proof and find the next item
          map.push [seek, @layers[thisLayer][thisItem][1]]
          seek = @web3Utils.soliditySha3({t:"bytes",v:@layers[thisLayer][thisItem][0]},{t:"bytes",v:@layers[thisLayer][thisItem][1]})
          #console.log 'new seek is ' + seek
          break
        if @layers[thisLayer][thisItem][1] is seek
          #console.log 'found seek in position 1'
          # push the item onto the proof and find the next item
          map.push [@layers[thisLayer][thisItem][0], seek]
          seek = @web3Utils.soliditySha3({t:"bytes",v:@layers[thisLayer][thisItem][0]},{t:"bytes",v:@layers[thisLayer][thisItem][1]})
          #console.log 'new seek is ' + seek
          break
        if thisItem is @layers[thisLayer].length
          throw 'seek not found'
    if seek is @root
      map.push [@root]
      return map
    else
      throw 'root not found'
  hasher:(val1, val2) =>
    console.log 'hashing ' + val1 + ' and ' + val2
    if val2?
      hash = @web3Utils.soliditySha3({t:"bytes32",v:val1},{t:"bytes32",v:val2})
    else
      hash = @web3Utils.soliditySha3({t:"bytes32",v:val1})
    return hash
  buildTree: ()=>
    if @layers[1]?.length > 0
      thrown new Error('Tree already exists.  Start a new tree')
    console.log @layers[0].length
    pair = []
    currentLayer = 0
    console.log 'currentLayer:' + currentLayer
    console.log 'currentLayer Length:' + @layers[currentLayer].length

    while @layers[currentLayer]? and @layers[currentLayer].length > 1
      console.log 'in layer loop'
      @layers.push []
      #console.log @layers
      console.log @layers[currentLayer]

      for thisItem in @layers[currentLayer]
        console.log thisItem
        #console.log 'odd item' if thisItem.length != 2

        if thisItem[1]?
          hash = @hasher thisItem[0], thisItem[1]
        else
          hash = @hasher thisItem[0]

        #console.log hash
        pair.push hash
        console.log pair.length
        if pair.length is 2
          console.log 'pushing hash'
          @layers[currentLayer + 1].push [pair[0],pair[1]]
          pair = []

      if pair.length > 0
        @layers[currentLayer + 1].push [pair[0]]
      console.log 'advancing layer'
      currentLayer = currentLayer + 1
      if currentLayer > 64
        throw new Error('yo')
    console.log 'done'
    console.log @layers
    console.log @layers[@layers.length - 1]
    console.log @layers[@layers.length - 1][0][0]
    console.log @layers[@layers.length - 1][0][1]
    @root = @hasher @layers[@layers.length - 1][0][0], @layers[@layers.length - 1][0][1]


exports.Tree = Tree