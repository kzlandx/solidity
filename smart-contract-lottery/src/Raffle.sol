// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample raffle contract
 * @author Kimy
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // ERRORS
    error Raffle__SendMoreToEnter();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    // TYPE DECLARATIONS
    enum RaffleState { OPEN, CALCULATING } // OPEN: 0, CALCULATING: 1

    // STATE VARIABLES
    uint256 private s_lastTimeStamp;
    address payable[] private s_players; // payable address array
    address private s_recentWinner;
    RaffleState private s_raffleState; // Start as OPEN
    
    // CONSTANT, IMMUTABLE VARIABLES
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery (in seconds)
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash; // Gas lane
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint32 constant NUM_WORDS = 1; // No. of random numbers to get
    uint16 constant REQUEST_CONFIRMATIONS = 3; // After how many block confirmations, should we get our random numbers

    // EVENTS
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    // CONSTRUCTOR
    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane,
        uint256 subcriptionId,
        uint32 callbackGasLimit) 
    VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subcriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }


    // MAIN FUNCTIONS
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH!"); // NOT GAS EFFICIENT
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnter();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        // Makes migration easier, also makes front end "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    // When should the winner be picked?
    /**
     * @dev This is the function that the chainlink nodes will call to see
     * if the lottery is ready to have a winner.
     * The following should be true for upkeepNeeded to be true:
     * 1. The time interval has passed between Raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicitly, your subscription has LINK.
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery.
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    // Requirements:
    // Get a random number, :DONE
    // Use it to pick a winner, :DONE
    // Also be automatically called :NOT DONE
    function performUpkeep(bytes calldata /* performData */) external { // "pickWinner()" renamed to "performUpkeep()"
        // Check if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        // NOT FULLY UNDERSTOOD YET
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false})) // True: Sepolia ETH, False: LINK
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId); // redundant
    }

    // Automatically called by the vrfcoordinator
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // CEI -> Checks, Effects, Interactions pattern
        // CHECKS


        // EFFECTS (Internal Contract State Updates)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(s_recentWinner);


        // INTERACTIONS (External Contract Interaction)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }


    // GETTER/VIEW FUNCTIONS
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 player_idx) external view returns (address) {
        return s_players[player_idx];
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
    
    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}