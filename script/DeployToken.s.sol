// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAuctionToken} from "../src/StealthAuctionToken.sol";

contract DeployToken is Script {
    function run() external {
        vm.startBroadcast();
        
        StealthAuctionToken token = new StealthAuctionToken("Stealth Auction Token", "SAT");
        
        console.log("StealthAuctionToken deployed at:", address(token));
        
        vm.stopBroadcast();
    }
}
