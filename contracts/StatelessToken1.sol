pragma solidity ^0.4.24;

contract StatelessToken1 {

    address public owner;
    bytes32 public root;
    uint256 public totalSupply;

    event NewBranch(bytes32 indexed addressFrom, bytes32 amountFrom, bytes32 indexed addressTo, bytes32 amountTo, bytes32 indexed parent);
    event SwapLeaf(bytes32 indexed oldLeaf, bytes32 indexed newLeaf);

    constructor() public {
        owner = msg.sender;
        totalSupply = 1000000 * 10**18;
        root = keccak256(
            abi.encodePacked(
                bytes32(msg.sender),
                bytes32(totalSupply)
                ));
        emit NewBranch(0x0, 0x0, bytes32(msg.sender), bytes32(totalSupply), 0x0);
    }

    function Transfer(address _to, uint256 _amount, bytes32[] proof) public {
        require(verifyProof(bytes32(msg.sender), proof[1], proof, root));
        require(_amount < uint256(proof[1]));
        root = splitBalance(bytes32(msg.sender), bytes32(uint256(proof[1]) - _amount), bytes32(_to), bytes32(_amount), proof);
    }

    function splitBalance(bytes32 _sender, bytes32 _senderBalance, bytes32 _to, bytes32 _toBalance, bytes32[] proof) private returns(bytes32){
       bytes32 lastHash;

       bytes32 newLeaf;

       require(_toBalance > 0);

       newLeaf = keccak256(
          abi.encodePacked(
              keccak256(abi.encodePacked(_sender, _senderBalance)),
              keccak256(abi.encodePacked(_to,_toBalance))));

       bytes32 newHash = newLeaf;

       for(uint thisProof = 0; thisProof < proof.length; thisProof++){
         if(thisProof == 0){
           //do nothing, this is what we are replacing
         } else if(thisProof == 1){
           lastHash = keccak256(abi.encodePacked(proof[0], proof[1]));
           if(lastHash == proof[2]){
            emit NewBranch(_sender, _senderBalance, _to,_toBalance, proof[2]);
           } else {
               emit NewBranch(_sender, _senderBalance, _to,_toBalance, proof[3]);
           }

           emit SwapLeaf(lastHash, newLeaf);
         } else if(thisProof == proof.length -1){

            //do nothing we have newHash
         }
         else{
           if(proof[thisProof] == lastHash){
             lastHash = keccak256(abi.encodePacked(lastHash, proof[thisProof + 1]));
             newHash = keccak256(abi.encodePacked(newHash, proof[thisProof + 1]));
             emit SwapLeaf(lastHash, newHash);
             //todo: check and swap equivalence in block
             thisProof++;
           } else {
             lastHash = keccak256(abi.encodePacked(proof[thisProof], lastHash));
             newHash = keccak256(abi.encodePacked(proof[thisProof], newHash));
             emit SwapLeaf(lastHash, newHash);
             //todo: check and swap equivalence in block
             thisProof++;
           }
         }

        }

       return newHash;
     }

     function updateBalance(bytes32 _sender, bytes32 _senderBalance, bytes32[] proof) constant public returns(bytes32){
       bytes32 lastHash;
       bytes32 newLeaf;
       bytes32 newHash;

       for(uint thisProof = 0; thisProof < proof.length; thisProof++){
         if(thisProof == 0){
           //do nothing, this is what we are replacing
         } else if(thisProof == 1){
           lastHash = keccak256(abi.encodePacked(proof[0], proof[1]));
           newLeaf = keccak256(abi.encodePacked(_sender, _senderBalance));
           emit SwapLeaf(lastHash, newLeaf);
         } else if(thisProof == proof.length -1){

            //do nothing we have newHash
         }
         else{
           if(proof[thisProof] == lastHash){
             lastHash = keccak256(abi.encodePacked(lastHash, proof[thisProof + 1]));
             newHash = keccak256(abi.encodePacked(newHash, proof[thisProof + 1]));
             emit SwapLeaf(lastHash, newHash);
             //todo: check and swap equivalince in block
             thisProof++;
           } else {
             lastHash = keccak256(abi.encodePacked(proof[thisProof], lastHash));
             newHash = keccak256(abi.encodePacked(proof[thisProof], newHash));
             emit SwapLeaf(lastHash, newHash);
             //todo: check and swap equivalince in block
             thisProof++;
           }
         }
        }
       return newHash;
     }

     function clearBalance(bytes32[] proof) constant public returns(bytes32){
       bytes32 lastHash;

       bytes32 newHash;

       for(uint thisProof = 0; thisProof < proof.length; thisProof++){
         if(thisProof == 0){
           //do nothing, this is what we are replacing
         } else if(thisProof == 1){
           lastHash = keccak256(abi.encodePacked(proof[0], proof[1]));
         } else if(thisProof == proof.length -1){

            //do nothing we have newHash
         }
         else{
           if(proof[thisProof] == lastHash){
             lastHash = keccak256(abi.encodePacked(lastHash, proof[thisProof + 1]));
             newHash = lastHash;
             emit SwapLeaf(lastHash, newHash);
             //todo: check and swap equivalince in block
             thisProof++;
           } else {
             lastHash = keccak256(abi.encodePacked(proof[thisProof], lastHash));
             newHash = lastHash;
             emit SwapLeaf(lastHash, newHash);
             //todo: check and swap equivalince in block
             thisProof++;
           }
         }
        }
       return newHash;
     }


    //utility function that can verify merkel proofs
    //todo: can be optimized
    //todo: move to library
    function verifyProof(bytes32 dataPath, bytes32 dataBytes, bytes32[] proof, bytes32 _root) pure public returns(bool){
       bytes32 lastHash;

       for(uint thisProof = 0; thisProof < proof.length; thisProof++){
         if(thisProof == 0){
           require(dataPath == proof[thisProof] );
         } else if(thisProof == 1){
           require(dataBytes == proof[thisProof]);
           lastHash = keccak256(abi.encodePacked(dataPath, dataBytes));
         } else if(thisProof == proof.length - 1){
            require(lastHash == proof[thisProof]);
         } else{
           if(proof[thisProof] == lastHash){
             lastHash = keccak256(abi.encodePacked(lastHash, proof[thisProof + 1]));
             thisProof++;
           } else {
             require(proof[thisProof + 1] == lastHash);
             lastHash = keccak256(abi.encodePacked(proof[thisProof], lastHash));
             thisProof++;
           }
         }

        }

       require(lastHash == _root);
       return true;
     }



}