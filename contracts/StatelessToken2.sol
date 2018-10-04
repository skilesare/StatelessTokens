pragma solidity ^0.4.24;

contract StatelessToken2 {

    address public owner;
    bytes32 public patriciaRoot;
    uint256 public totalSupply;

    event NewBalance(address owner, bytes32 key, bytes32 value);
    event NewRoot(bytes32 newRoot);
    event calcingHex(bytes32[16] list);

    constructor() public{
        //constructor
        owner = msg.sender;
        totalSupply = 1000000 * 10**18;
        patriciaRoot =
        patriciaRoot =  keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(keccak256("balance"),bytes32(msg.sender))),
                bytes32(totalSupply)
                )
        );
        emit NewBalance(msg.sender, keccak256(abi.encodePacked(keccak256("balance"),bytes32(msg.sender))), bytes32(totalSupply));
    }

    function verifySuperProof(bytes32[] proof) pure public returns(bytes32){
        //proof[0] = key
        //proof[1] = value

        bytes32 lastHash;

        if(proof[1] == 0x0){
            //if the first value is 0 then the hash will be 0 up until we hit the merge point with existing data
            lastHash = 0x0;
        } else {
            lastHash = keccak256(abi.encodePacked(proof[0], proof[1]));
        }

        bytes32[16] memory list;
        uint currentPosition;

        uint thisKeyByte = 0;
        uint currentKeyPosition = 0;
        bool bFoundHash = false;

        //we split into 4 groups so we can follow the map in proof[2-5]
        for(uint thisHashGroup = 0; thisHashGroup < 4 ; thisHashGroup++){
            if(proof[2 + thisHashGroup] == 0x0){
                thisKeyByte = thisKeyByte + 8;
                currentKeyPosition = currentKeyPosition + 16;
                continue;
            }
            for(uint thisHashByte = 0; thisHashByte < 32 ; thisHashByte++){

                //create a list for the current level
                if(proof[2 + thisHashGroup][thisHashByte] == 0x0 && proof[2 + thisHashGroup][thisHashByte + 1]== 0x0){
                    //we can save a lot of gas by skipping this if the map is 00000000 00000000

                }
                else {
                    (list, bFoundHash, currentPosition) = createList([proof[2 + thisHashGroup][thisHashByte], proof[2 + thisHashGroup][thisHashByte + 1]], getKeyHalf(currentKeyPosition, thisKeyByte, proof), currentPosition, lastHash, proof);
                    //(lastHash, currentPosition) = createList([proof[2 + thisHashGroup][thisHashByte], proof[2 + thisHashGroup][thisHashByte + 1]], getKeyHalf(currentKeyPosition, thisKeyByte, proof), currentPosition, lastHash, proof);


                    if(bFoundHash){
                        //if we found data in this level we need to calculate the hex hash
                        //calcingHex(list);
                        lastHash = hexHash(list);
                    }
                }

                    bFoundHash = false;
                    currentKeyPosition++;

                    if(currentKeyPosition % 2 == 0){
                        //each key position need to advance every two ints
                        thisKeyByte++;
                    }

                    thisHashByte ++;
            }
        }

        return  lastHash;
     }

    function superTransfer(address destination, uint256 amount, bytes32[] memory destinationProof, bytes32[] memory senderProof) public returns(bytes32) {
        //this function transfers tokens from one address to another

        //make sure we are sending a positive amount of tokens
        require(uint256(senderProof[1]) >= amount);

        //make sure the sender actually sent this transaction
        require(keccak256(abi.encodePacked(keccak256("balance"), bytes32(msg.sender))) == senderProof[0]);

        //makesure that the proof is proving the destination
        require(keccak256(abi.encodePacked(keccak256("balance"), bytes32(destination))) == destinationProof[0]);

        //make sure that the destination proof renders to the current patriciaRoot
        require(verifySuperProof(destinationProof) == patriciaRoot);

        //makes sure that the sender proof renders to the current patriciaRoot
        require(verifySuperProof(senderProof) == patriciaRoot);


        uint commonPosition;
        uint8 senderHalf;
        uint8 destinationHalf;

        //calculate the common position where the sender balance meets the destination balance
        (commonPosition, senderHalf, destinationHalf) = findCommonPosition(senderProof[0],destinationProof[0]);

        //update the sender proof
        senderProof[1] = bytes32(uint256(senderProof[1]) - amount);

        //update the destination proof
        destinationProof[1] = bytes32(uint256(destinationProof[1]) + amount);

        bytes32 senderHash;
        bytes32 destinationHash;
        bytes32[16] memory list;
        uint256 currentPosition;
        uint256 irrPosition;

        //build the sender Proof to the join point
        (senderHash, list, currentPosition) = buildSuperProofToPosition(senderProof, commonPosition);

        //build the dest Poof to the join point
        (destinationHash, list, irrPosition) = buildSuperProofToPosition(destinationProof, commonPosition);

        //get the current state of the join layer
        (list,,currentPosition) = createList([senderProof[2 + (commonPosition/16)][(commonPosition % 16) *2], senderProof[2+(commonPosition/16)][((commonPosition % 16) *2)+ 1]], getKeyHalf(commonPosition % 2, commonPosition / 2, senderProof), currentPosition, senderHash, senderProof);

        //update the list witht he new values
        list[senderHalf] = senderHash;
        list[destinationHalf] = destinationHash;

        //recalc the hash
        assembly{
            senderHash := keccak256(list,512)
        }
        //calcingHex(list);

        //calculate the new root from the join point up to the root
        patriciaRoot =  buildSuperProofPastPosition(senderProof, commonPosition + 1, currentPosition, senderHash);

        //log events
        emit NewRoot(patriciaRoot);
        emit NewBalance(msg.sender, senderProof[0],senderProof[1]);
        emit NewBalance(destination, destinationProof[0], destinationProof[1]);
        return patriciaRoot;
     }

    function createList(byte[2] memory pair, uint16 keyHalf, uint currentPosition, bytes32 lastHash, bytes32[] proof) pure public returns(bytes32[16] memory list, bool bFoundHash, uint newPosition){
        //this function builds a list layer based on a proof and the map

        if(pair[0] == 0x0 && pair[1]== 0x0){
            //we can save a lot of gas by skipping this if the map is 00000000 00000000
            return;
        }

        //convert the map to to a binary list
        bool[16] memory mapList = buildHashLayerMap(pair[0],pair[1]);
        newPosition = currentPosition;

        //loop throug the binary list and build the hex list of hashes
        for(uint thisListPosition = 0; thisListPosition < 16; thisListPosition++){

            if(thisListPosition == keyHalf){
                //add our current hash value at our current position
                list[thisListPosition]= lastHash;
            } else if (mapList[thisListPosition]){
                //if the map has a 1 we need to add the current has an let our function know to move on to the next hash
                if(proof[6 + newPosition] == lastHash){
                    newPosition++;
                }
                list[thisListPosition] = proof[6 + newPosition];
                bFoundHash = true;
                newPosition++;
            }
        }
    }
    /*
    function createList(byte[2] memory pair, uint16 keyHalf, uint currentPosition, bytes32 lastHash, bytes32[] proof) pure returns(bytes32 newHash, uint newPosition){
        //this function builds a list layer based on a proof and the map
        newHash = lastHash;
        newPosition = currentPosition;

        if(pair[0] == 0x0 && pair[1]== 0x0){
            //we can save a lot of gas by skipping this if the map is 00000000 00000000
            return;
        }
        bytes32[16] memory list;
        //convert the map to to a binary list
        bool[16] memory mapList = buildHashLayerMap(pair[0],pair[1]);

        uint hashCount;
        //loop throug the binary list and build the hex list of hashes
        for(uint thisListPosition = 0; thisListPosition < 16; thisListPosition++){

            if(thisListPosition == keyHalf){
                //add our current hash value at our current position
                list[thisListPosition]= lastHash;

            } else if (mapList[thisListPosition]){
                //if the map has a 1 we need to add the current has an let our function know to move on to the next hash
                if(proof[6 + newPosition] == lastHash){
                    newPosition++;
                    hashCount ++;
                }
                newHash = proof[6 + newPosition];
                list[thisListPosition] = proof[6 + newPosition];
                newPosition++;
            }
        }

        if(hashCount > 1){
            assembly{
                newHash := keccak256(list,512)
            }
        }


    }
    */


    function buildHashLayerMap(byte firstByte, byte secondByte) pure public returns(bool[16] result){
        assembly {
          mstore(result, eq(and(0x8000000000000000000000000000000000000000000000000000000000000000, firstByte), 0x8000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 32), eq(and(0x4000000000000000000000000000000000000000000000000000000000000000, firstByte), 0x4000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 64), eq(and(0x2000000000000000000000000000000000000000000000000000000000000000, firstByte), 0x2000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 96), eq(and(0x1000000000000000000000000000000000000000000000000000000000000000, firstByte), 0x1000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 128), eq(and(0x0800000000000000000000000000000000000000000000000000000000000000, firstByte), 0x0800000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 160), eq(and(0x0400000000000000000000000000000000000000000000000000000000000000, firstByte), 0x0400000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 192), eq(and(0x0200000000000000000000000000000000000000000000000000000000000000, firstByte), 0x0200000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 224), eq(and(0x0100000000000000000000000000000000000000000000000000000000000000, firstByte), 0x0100000000000000000000000000000000000000000000000000000000000000))

          mstore(add(result, 256), eq(and(0x8000000000000000000000000000000000000000000000000000000000000000, secondByte), 0x8000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 288), eq(and(0x4000000000000000000000000000000000000000000000000000000000000000, secondByte), 0x4000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 320), eq(and(0x2000000000000000000000000000000000000000000000000000000000000000, secondByte), 0x2000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 352), eq(and(0x1000000000000000000000000000000000000000000000000000000000000000, secondByte), 0x1000000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 384), eq(and(0x0800000000000000000000000000000000000000000000000000000000000000, secondByte), 0x0800000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 416), eq(and(0x0400000000000000000000000000000000000000000000000000000000000000, secondByte), 0x0400000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 448), eq(and(0x0200000000000000000000000000000000000000000000000000000000000000, secondByte), 0x0200000000000000000000000000000000000000000000000000000000000000))
          mstore(add(result, 480), eq(and(0x0100000000000000000000000000000000000000000000000000000000000000, secondByte), 0x0100000000000000000000000000000000000000000000000000000000000000))

        }
     }


    function hexHash(bytes32[16] list) pure public returns (bytes32 newHash){
        //calculates the has of a list of 16 hashes
        //if there is only one item we only need to return the one hash we findor
        //empty hash

        uint count = 0;
        for(uint thisItem = 0; thisItem < 16; thisItem ++){
            if(list[thisItem] != 0x0){
                newHash = list[thisItem];
                count++;
                if(count > 1){
                    break;
                }
            }
        }

        if(count > 1){
            //we found more than one hash so calc the hash
            assembly{
                newHash := keccak256(list,512)
            }
        }

     }

     function findCommonPosition(bytes32 key1, bytes32 key2) pure public returns(uint currentPosition, uint8 keyHalf1, uint8 keyHalf2){

        //cycles through the address of the source and dest keys and finds where their patricia root calcs should merge

        currentPosition = 63;
        for(uint thisHashByte = 0; thisHashByte < 32 ; thisHashByte++){

        keyHalf1 = uint8(key1[thisHashByte]) / 16;
        keyHalf2 = uint8(key2[thisHashByte]) / 16;
        if(keyHalf1 != keyHalf2){
            return;
        }

        currentPosition--;

        keyHalf1 = uint8(key1[thisHashByte] & byte(0x0F));
        keyHalf2 = uint8(key2[thisHashByte] & byte(0x0F));
        if(keyHalf1 != keyHalf2){
            return;
        }

        currentPosition--;


        }

        return;

     }

     function getKeyHalf(uint currentKeyPosition, uint thisKeyByte, bytes32[] proof) pure public returns (uint8 keyHalf){
        //find the current key half
        //thisKeyByte = currentKeyPosition / 2;
        if(currentKeyPosition % 2 == 0 && thisKeyByte < 32){
            keyHalf = uint8(proof[0][32 - thisKeyByte - 1] & byte(0x0F));
        } else {
            keyHalf = uint8(proof[0][32 - thisKeyByte - 1]) / 16;
        }
     }




    function buildSuperProofToPosition(bytes32[] proof, uint position) pure public returns(bytes32 lastHash, bytes32[16] memory list, uint256 currentPosition) {
        //calcs an update hash up to a common position
        if(proof[1] == 0x0) {
            lastHash = 0x0;
        } else {
            lastHash = keccak256(abi.encodePacked(proof[0], proof[1]));
        }



        uint thisKeyByte = 0;
        uint currentKeyPosition = 0;
        bool bFoundHash = false;

        for(uint thisHashGroup = 0; thisHashGroup < 4 ; thisHashGroup++) {

            if((thisHashGroup * 16) + (thisHashByte / 2) >= position - 1) {
                return;
            }
            if(proof[2 + thisHashGroup] == 0x0){
                thisKeyByte = thisKeyByte + 8;
                currentKeyPosition = currentKeyPosition + 16;
                continue;
            }

            for(uint thisHashByte = 0; thisHashByte < 32 ; thisHashByte++) {
                //get the current list at this layer

                if(proof[2 + thisHashGroup][thisHashByte] == 0x0 && proof[2 + thisHashGroup][thisHashByte + 1]== 0x0){
                    //we can save a lot of gas by skipping this if the map is 00000000 00000000

                } else {
                    (list, bFoundHash, currentPosition) = createList([proof[2 + thisHashGroup][thisHashByte], proof[2 + thisHashGroup][thisHashByte + 1]], getKeyHalf(currentKeyPosition, thisKeyByte, proof), currentPosition, lastHash, proof);
                    //(lastHash, currentPosition) = createList([proof[2 + thisHashGroup][thisHashByte], proof[2 + thisHashGroup][thisHashByte + 1]], getKeyHalf(currentKeyPosition, thisKeyByte, proof), currentPosition, lastHash, proof);

                    if(bFoundHash){
                        //recalc a hash
                        //calcingHex(list);
                        lastHash = hexHash(list);
                    }
                }

                bFoundHash = false;
                currentKeyPosition++;

                if(currentKeyPosition % 2 == 0){
                    thisKeyByte++;
                }

                thisHashByte ++;

                if((thisHashGroup * 16) + (thisHashByte / 2) >= position - 1) {
                    return;
                }


            }
        }
        return;
     }

     function buildSuperProofPastPosition(bytes32[] proof, uint position, uint256 currentPosition, bytes32 lastHash) pure public returns(bytes32) {
        // calculates the patricia root for a proof past a common position
        if(position >= 63){
            return lastHash;
        }
        uint thisKeyByte = position/2;
        uint currentKeyPosition = 0;
        bool bFoundHash = false;
        bytes32[16] memory list;

        uint thisHashGroup = position/16;

        for(thisHashGroup = thisHashGroup; thisHashGroup < 4 ; thisHashGroup++){

            if(proof[2 + thisHashGroup] == 0x0){
                thisKeyByte = (thisHashGroup + 1) * 8;
                currentKeyPosition = (thisHashGroup + 1) * 16;
                continue;
            }

            uint thisHashByte;
            if(thisHashGroup == position/16){

                thisHashByte = (position * 2) - (thisHashGroup * 16 * 2);

            } else {
                thisHashByte = 0;
            }

            for(thisHashByte = thisHashByte; thisHashByte < 32 ; thisHashByte++){

                //find the list at the current list
                if(proof[2 + thisHashGroup][thisHashByte] == 0x0 && proof[2 + thisHashGroup][thisHashByte + 1]== 0x0){
                    //we can save a lot of gas by skipping this if the map is 00000000 00000000

                } else {
                    (list, bFoundHash, currentPosition) = createList([proof[2 + thisHashGroup][thisHashByte], proof[2 + thisHashGroup][thisHashByte + 1]], getKeyHalf(currentKeyPosition, thisKeyByte, proof), currentPosition, lastHash, proof);
                    //(lastHash, currentPosition) = createList([proof[2 + thisHashGroup][thisHashByte], proof[2 + thisHashGroup][thisHashByte + 1]], getKeyHalf(currentKeyPosition, thisKeyByte, proof), currentPosition, lastHash, proof);

                    if(bFoundHash){
                        //calcingHex(list);
                        lastHash = hexHash(list);
                    }
                }
                bFoundHash = false;
                currentKeyPosition++;
                if(currentKeyPosition % 2 == 0){
                    thisKeyByte++;
                }
                thisHashByte ++;
            }
        }
        return lastHash;
    }
}