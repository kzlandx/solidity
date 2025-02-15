// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// INTERACTIONS WITH FUNDME CONTRACT : FUND, WITHDRAW

import {Script, console} from "lib/forge-std/src/Script.sol";
import {FundMe} from "src/FundMe.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;
    
    function fundFundMe(address _mostRecentDeployment) public {
        vm.startBroadcast();
        FundMe(payable(_mostRecentDeployment)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentDeployment);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address _mostRecentlyDeployment) public {
        vm.startBroadcast();
        FundMe(payable(_mostRecentlyDeployment)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address mostRecentlyDeployment = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployment);
    }

}