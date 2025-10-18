// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {MockPyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract PythInteractions is Script {
    // function run() external {
    //     address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MockPyth", block.chainid);

    //     createPriceFeed(mostRecentlyDeployed, "ETH/USD", 4000);
    //     createPriceFeed(mostRecentlyDeployed, "BTC/USD", 100_000);
    // }

    function createPriceFeed(address _pythAddress, bytes32 _priceFeedId, int64 _price, string memory _pair) public {
        bytes[] memory updateData = new bytes[](1);

        MockPyth pyth = MockPyth(_pythAddress);

        vm.startBroadcast(address(this));
        updateData[0] = pyth.createPriceFeedUpdateData(
            _priceFeedId, // priceFeedId
            _price * 100000, // price
            10 * 100000, // confidence
            -5, // exponent
            _price * 100000, // emaPrice
            10 * 100000, // emaConfidence
            uint64(block.timestamp), // publishTime
            uint64(block.timestamp) // prevPublishTime
        );
        vm.stopBroadcast();

        uint256 value = pyth.getUpdateFee(updateData);

        vm.deal(address(this), value);
        pyth.updatePriceFeeds{value: value}(updateData);

        console2.log("Created price feed %s", _pair);
        console2.log("For price %s", _price);
    }
}
