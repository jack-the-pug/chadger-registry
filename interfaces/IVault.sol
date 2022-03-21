// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVault {
    function initialize(
        address token,
        address governance,
        address keeper,
        address guardian,
        address treasury,
        address strategist,
        address badgerTree,
        string memory name,
        string memory symbol,
        uint256[4] memory feeConfig
    ) external;

    function name() external view returns (string memory);

    function version() external view returns (string memory);

    function token() external view returns (address);

    function strategist() external view returns (address);

    function governance() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address) external;

    function deposit(uint256) external;

    function balance() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function lastHarvestedAt() external view returns (uint256);

    function reportAdditionalToken(address) external;
}
