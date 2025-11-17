// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {MockERC20} from "../../src/mock/MockERC20.sol";

contract ERC20Deploy is Script {
    function run() public {
        deploy(msg.sender, "Wrapped Ethereum", "WETH");
        deploy(msg.sender, "Wrapped Bitcoin", "WBTC");
    }

    function deploy(address _deployer, string memory _name, string memory _symbol) public returns (ERC20) {
        console2.log("Deployer for ERC20 ", _name, " is: ", _deployer);
        
        vm.startBroadcast(_deployer);
        MockERC20 erc20 = new MockERC20(_name, _symbol);
        vm.stopBroadcast();

        return erc20;
    }
}
