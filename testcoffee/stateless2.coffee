console.log 'hello'
web3Utils = require('web3-utils')
Tree = require('../src/patriciaTree.js')

StatelessTokenBackup =  artifacts.require('./StatelessToken2.sol')


###
todo:
- move values into a generic store for easier upgrades
- add upgrade path

###


contract 'StatelessToken', (paccount)->
  owner = paccount[0]
  secondOwner = paccount[1]
  networkOwner = paccount[2]
  foundation = paccount[6]


  it "can set run code ", ->



    #add stake to be transfered
    console.log 'superhash'


    instance = await StatelessTokenBackup.new(from: paccount[1])
    hash = await instance.verifySuperProof.call(["0x0000000000000000000000000000000000000000000000000000000000000001","0x0000000000000000000000000000000000000000000000000000000000000001","0x6000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x679795a0195a1b76cdebb7c51d74e058aee92919b8c3389af86ef24535e8a28c"])
    console.log hash
  it "can verify zero value ", ->

    console.log 'zero val'
    instance = await StatelessTokenBackup.new(from: paccount[1])
    hash = await instance.verifySuperProof.call(["0x0000000000000000000000000000000000000000000000000000000000000020","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000800000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x33fdfe3546a984dbb5361c63023925cec94a0e18e655191213f7ac6b7376fd97"])
    console.log hash


  it "transfer tokens 2", ->
    #create a new instance
    instance = await StatelessTokenBackup.new(from: paccount[1])

    console.log 'have instance....starting balance proof'

    startingBalanceProof = [
      web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(paccount[1],64))
      "0x00000000000000000000000000000000000000000000d3c21bcecceda1000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    ]
    console.log 'starting Balance Proof built manually'
    console.log startingBalanceProof

    #test that the verify superProof call works
    expectedRoot = await instance.verifySuperProof.call(startingBalanceProof)
    patriciaRoot = await instance.patriciaRoot.call()

    assert.equal expectedRoot, patriciaRoot, 'roots didnt match'

    console.log "initial root:"
    console.log patriciaRoot

    console.log 'determining proofs'

    #create a new tree object
    tree = new Tree.PatriciaTree()
    tree.addItem(startingBalanceProof[0],startingBalanceProof[1])

    tree.buildTree()

    console.log 'original root'
    console.log tree.root

    #make sure the object's root matches the contract root
    assert.equal tree.root, patriciaRoot, 'roots didnt match'


    sourceBalance = web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(paccount[1],64))

    newAmount = web3Utils.toWei("1000000","ether")
    newAmount = new web3Utils.BN(newAmount)
    removeAmount = new web3Utils.BN("10")

    #in this test we will look for items that match match at the start of the key
    #use testrpc -l 9000000 -a 1000 -e 1000000000000 to generate a bunch of addreses
    for thisAccount in [0..89]
      console.log 'looking accounts'
      console.log thisAccount
      console.log 10 + thisAccount
      destbalanckey = web3Utils.soliditySha3(web3Utils.soliditySha3('balance'), web3Utils.padLeft(paccount[10 + thisAccount],64))
      #if(destbalanckey.substring(2,4) isnt sourceBalance.substring(2,4))
      #  continue
      console.log 'looking for starting balance'
      startingBalanceProof = tree.getProof(web3Utils.padLeft(sourceBalance,64))

      destProof = tree.getProof(web3Utils.soliditySha3(web3Utils.soliditySha3('balance'), web3Utils.padLeft(paccount[10 + thisAccount],64)))
      console.log startingBalanceProof
      console.log destProof
      console.log paccount[10 + thisAccount]

      console.log 'calling super transfer'
      trx = await instance.superTransfer(paccount[10 + thisAccount], web3Utils.toWei("10","wei"), destProof, startingBalanceProof, from: paccount[1])
      console.log 'gas used: ' + trx.receipt.gasUsed

      patriciaRoot = await instance.patriciaRoot.call()
      console.log 'updating amounts'

      newAmount = newAmount.sub(removeAmount)

      #recalc the tree
      tree.addItem(sourceBalance,web3Utils.padLeft(web3Utils.numberToHex(newAmount),64))
      tree.addItem(web3Utils.soliditySha3(web3Utils.soliditySha3('balance'),web3Utils.padLeft(paccount[10 + thisAccount],64)), web3Utils.padLeft(web3Utils.numberToHex(10),64))
      tree.buildTree()

      console.log 'newRoot'
      console.log tree.root

      console.log patriciaRoot
      assert.equal tree.root, patriciaRoot, 'roots did not match'
  ###
  it "transfer tokens ", ->

    #add stake to be transfered
    console.log 'creating'


    instance = await StatelessTokenBackup.new(from: paccount[1])
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

















