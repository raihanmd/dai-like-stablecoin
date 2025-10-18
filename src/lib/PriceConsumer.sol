// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {PythUtils} from "@pythnetwork/pyth-sdk-solidity/PythUtils.sol";

import {console2} from "forge-std/console2.sol";

library PriceConsumer {
    uint256 constant PRICE_PRECISION = 1e18;

    function oracle_getPricePull(IPyth _pythContract, bytes32 _priceFeedId, bytes[] calldata priceUpdate)
        internal
        returns (uint256)
    {
        uint256 fee = _pythContract.getUpdateFee(priceUpdate);
        _pythContract.updatePriceFeeds{value: fee}(priceUpdate);

        PythStructs.Price memory price = _pythContract.getPriceNoOlderThan(_priceFeedId, 60);

        uint256 convertedPrice = PythUtils.convertToUint(price.price, price.expo, 18);

        return convertedPrice;
    }

    function oracle_getPricePush(IPyth _pythContract, bytes32 _priceFeedId) internal view returns (uint256) {
        PythStructs.Price memory price = _pythContract.getPriceNoOlderThan(_priceFeedId, 60);

        uint256 convertedPrice = PythUtils.convertToUint(price.price, price.expo, 18);

        return convertedPrice;
    }

    // function getPriceUnsafe(IPyth _pythContract, bytes32 _priceFeedId) internal view returns (uint256) {
    //     PythStructs.Price memory price = _pythContract.getPriceUnsafe(_priceFeedId);
    //     uint256 convertedPrice = PythUtils.convertToUint(price.price, price.expo, 18);
    //     return convertedPrice;
    // }

    // function getConversionRate(
    //     uint256 _ethAmount,
    //     IPyth _priceFeed
    // ) internal view returns (uint256) {
    //     uint256 ethPrice = getPrice(_priceFeed);
    //     return (_ethAmount * ethPrice) / 1e18;
    // }
}
