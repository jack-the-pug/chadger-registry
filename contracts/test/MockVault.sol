// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Vault} from "@badger-finance/Vault.sol";

contract MockVault is Vault {
  // So Brownie compiles it tbh
  // Changes here invalidate the bytecode, breaking trust of the mix
  // DO NOT CHANGE THIS FILE
}