// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {PythUtils} from "@pythnetwork/pyth-sdk-solidity/PythUtils.sol";

import {console2} from "forge-std/console2.sol";

library PriceConsumer {
    uint256 constant PRICE_PRECISION = 1e18;

    // function oracle_getPricePull(
    //     IPyth _pythContract,
    //     bytes32 _priceFeedId,
    //     bytes[] calldata priceUpdate,
    //     uint256 _maxAge
    // ) internal returns (uint256) {
    //     uint256 fee = _pythContract.getUpdateFee(priceUpdate);
    //     _pythContract.updatePriceFeeds{value: fee}(priceUpdate);

    //     PythStructs.Price memory price = _pythContract.getPriceNoOlderThan(_priceFeedId, _maxAge);

    //     uint256 convertedPrice = PythUtils.convertToUint(price.price, price.expo, 18);

    //     return convertedPrice;
    // }

    function oracle_getPricePush(IPyth _pythContract, bytes32 _priceFeedId, uint256 _maxAge)
        internal
        view
        returns (uint256)
    {
        PythStructs.Price memory price = _pythContract.getPriceNoOlderThan(_priceFeedId, _maxAge);

        uint256 convertedPrice = PythUtils.convertToUint(price.price, price.expo, 18);

        return convertedPrice;
    }
}
