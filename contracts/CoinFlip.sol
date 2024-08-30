pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract CoinFlip is VRFV2WrapperConsumerBase {
    enum CoinFlipSelection {
        HEADS,
        TAILS
    }

    struct CoinFlipStatus {
        uint256 fees;
        uint256 randomWord;
        address player;
        bool didWin;
        bool fulfilled;
        CoinFlipSelection choice;
    }

      uint128 constant entryFees = 0.001 ether;
    uint32 constant callbackGasLimit = 100000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;

    event CoinFlipRequest(uint256 requestId);
    event CoinFlipResult(uint256 requestId, bool didWin);

    mapping(uint256 => CoinFlipStatus) public statuses;

    constructor() VRFV2WrapperConsumerBase(linkAddress, vrfWrapperAddress) {}

    function flip(CoinFlipSelection choice) external payable returns (uint256) {
        require(msg.value == entryFees, "Fees not sent.");
        uint256 requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);

        statuses[requestId] = CoinFlipStatus({
            fees: VRFV2WrapperConsumerBase.VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWord: 0,
            player: msg.sender,
            didWin: false,
            fulfilled: false,
            choice: choice
        });

        emit CoinFlipRequest(requestId);
        return requestId;
    }

    address constant linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant vrfWrapperAddress = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
  

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(statuses[requestId].fees > 0, "Request not found");

        statuses[requestId].fulfilled = true;
        statuses[requestId].randomWord = randomWords[0];
        CoinFlipSelection result = CoinFlipSelection.HEADS;
        if (randomWords[0] % 2 == 0) {
            result = CoinFlipSelection.TAILS;
        }
        if (statuses[requestId].choice == result) {
            statuses[requestId].didWin = true;
            payable(statuses[requestId].player).transfer(entryFees * 2);
        }
        emit CoinFlipResult(requestId, statuses[requestId].didWin);
    }

    function getStatus(uint256 requestId) public view returns (CoinFlipStatus memory) {
        return statuses[requestId];
    }
}
