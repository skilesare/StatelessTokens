console.log 'hello'
web3Utils = require('web3-utils')
Tree = require('../src/tree.js')

StatelessToken =  artifacts.require('./StatelessToken1.sol')


###
todo:


###


contract 'StatelessToken1', (paccount)->
  owner = paccount[0]
  reciever = paccount[1]
  networkOwner = paccount[2]
  foundation = paccount[6]

  it "can create known root ", ->
    instance = await StatelessToken.new(from: owner)

    console.log 'we have an instance'

    tree = new Tree.Tree()
    tree.addItem(
        web3Utils.padLeft(owner,64),

        web3Utils.padLeft(
          web3Utils.numberToHex(
            web3Utils.toWei("1000000","ether")),64
          )
      )
    tree.buildTree()
    console.log 'tree built'
    console.log tree.root

    root =  await instance.root.call()
    console.log 'the contract root is'
    console.log root
    assert.equal(root, tree.root)


  it "can verify initial balance", ->

    instance = await StatelessToken.new(from: owner)

    console.log 'we have an instance'

    tree = new Tree.Tree()
    tree.addItem(
        web3Utils.padLeft(owner,64),

        web3Utils.padLeft(
          web3Utils.numberToHex(
            web3Utils.toWei("1000000","ether")),64
          )
      )

    tree.buildTree()
    proof = tree.getProof(web3Utils.padLeft(owner,64))

    console.log 'proof'
    console.log [].concat(...proof)

    result =  await instance.verifyProof.call(web3Utils.padLeft(owner,64), web3Utils.padLeft(web3Utils.numberToHex(web3Utils.toWei("1000000","ether")),64), [].concat(...proof), tree.root)
    console.log 'the result'
    console.log result
    assert.equal(result, true)


  it "can transfer tokens", ->
    #create a new instance
    instance = await StatelessToken.new(from: owner)

    console.log 'we have an instance'

    tree = new Tree.Tree()
    tree.addItem(
        web3Utils.padLeft(owner,64),

        web3Utils.padLeft(
          web3Utils.numberToHex(
            web3Utils.toWei("1000000","ether")),64
          )
      )

    tree.buildTree()
    proof = tree.getProof(web3Utils.padLeft(owner,64))

    console.log 'proof'
    console.log [].concat(...proof)

    trx =  await instance.Transfer(
      reciever
      web3Utils.toWei("100","ether")
      [].concat(...proof)
      {from: owner}
    )

    console.log 'the transaction'
    console.log trx

    for i in trx.logs
      console.log i
      for thisarg in i.args
        console.log thisarg


    assert.equal(true, true)

###
  it "transfer tokens ", ->

    #add stake to be transfered
    console.log 'creating'


    instance = await StatelessToken.new(from: paccount[1])
    console.log paccount[1]
    console.log '["' + web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(paccount[1],64)) + "," + "0x00000000000000000000000000000000000000000000d3c21bcecceda1000000" + "," + "0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000"

    startingBalanceProof = [
      web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(paccount[1],64))
      "0x00000000000000000000000000000000000000000000d3c21bcecceda1000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    ]
    console.log startingBalanceProof



    expectedRoot = await instance.verifySuperProof.call(startingBalanceProof)
    patriciaRoot = await instance.patriciaRoot.call()

    assert.equal expectedRoot, patriciaRoot, 'roots didnt match'

    console.log patriciaRoot

    console.log 'determining proofs'

    tree = new Tree.PatriciaTree()

    tree.addItem(startingBalanceProof[0],startingBalanceProof[1])

    console.log tree.items
    tree.buildTree()

    anAccount = null
    sourceBalance = web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(paccount[1],64))
    console.log 'solving balanace'
    console.log sourceBalance
    thisAccountBalance = null
    for thisAccount in paccount

      thisAccountBalance = web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(thisAccount,64))
      console.log thisAccountBalance

      if sourceBalance isnt thisAccountBalance and sourceBalance.substring(3,1) == thisAccountBalance.substring(3,1)
        console.log 'found acccount'
        console.log sourceBalance
        console.log thisAccountBalance
        console.log paccount[1]
        console.log thisAccount
        anAccount = thisAccount
        break

    assert.equal tree.root, patriciaRoot, 'roots didnt match'
    console.log 'calcing dest proof'
    destinationProof = tree.getProof(web3Utils.soliditySha3(web3Utils.soliditySha3('balance'), web3Utils.padLeft(anAccount,64)))
    console.log destinationProof

    console.log 'about to supertransfer2'
    console.log startingBalanceProof
    assert.equal web3Utils.soliditySha3(startingBalanceProof[0],startingBalanceProof[1]), patriciaRoot, 'roots dont match'
    result = await instance.superTransfer2.call(anAccount, 10, destinationProof, startingBalanceProof, from: paccount[1])

    console.log destinationProof[0]
    console.log startingBalanceProof[0]

    console.log 'supertransfer2'
    #position comes back as 64
    console.log result
    #console.log result.toNumber()


    newAmount = web3Utils.toWei("1000000","ether")
    newAmount = new web3Utils.BN(newAmount)
    removeAmount = new web3Utils.BN("10")
    newAmount = newAmount.sub(removeAmount)
    console.log newAmount
    console.log web3Utils.numberToHex(newAmount)
    console.log web3Utils.padLeft(web3Utils.numberToHex(newAmount),64)
    tree.addItem(sourceBalance,web3Utils.padLeft(web3Utils.numberToHex(newAmount),64))
    tree.addItem(thisAccountBalance,web3Utils.padLeft(web3Utils.numberToHex(10),64))
    tree.buildTree()

    console.log 'root:'
    console.log tree.root
    console.log tree.getProof(web3Utils.padLeft(sourceBalance,64))
    console.log tree.getProof(web3Utils.padLeft(thisAccountBalance,64))


    #assert.equal tree.root, result, 'roots did not match'


    console.log 'about to supertransfer'


    trx = await instance.superTransfer(anAccount, web3Utils.toWei("10","wei"), destinationProof, startingBalanceProof, from: paccount[1])
    console.log trx
    #for thisEvent in trx.logs
    #  console.log thisEvent.args

    patriciaRoot = await instance.patriciaRoot.call()
    console.log 'patricia root'
    console.log patriciaRoot
    assert.equal tree.root, patriciaRoot, 'roots did not match'
  ###

















