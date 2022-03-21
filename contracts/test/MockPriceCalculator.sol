// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
import  "../../interfaces/IPriceCalculator.sol";

contract MockPriceCalculator is IPriceCalculator {
	    function tokenPriceInUSD(address tokenAddress, uint amount)  external override view returns (uint256) {
				return amount;
			}
}