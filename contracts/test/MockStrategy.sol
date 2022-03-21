// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IVault.sol";

contract MockStrategy is IStrategy {
    address public want;
    address public testRewardToken;
    address public vault;
    address public governance;
    uint256 public constant MAX_BPS = 10_000;
    uint256 public lossBps = 500;
    string public override name = "MockStrategy";

    function initialize(
        address _vault,
        address _want,
        address _governance
    ) public override {
        vault = _vault;
        want = _want;
        governance = _governance;
    }

    function setTestRewardToken(address token) external {
        testRewardToken = token;
    }

    function balanceOf() external view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    function balanceOfWant() public view override returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function getProtectedTokens()
        public
        view
        virtual
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](2);
        protectedTokens[0] = want;
        return protectedTokens;
    }

    function _isTendable() internal pure returns (bool) {
        return true;
    }

    function deposit(uint256 _amount) internal {
        // No-op as we don't do anything
    }

    function withdrawToVault() external override {
        _withdrawAll();
        uint256 balance = IERC20Upgradeable(want).balanceOf(address(this));
        _transferToVault(balance);
    }

    function withdraw(uint256 _amount) external override {
        _withdrawSome(_amount);
        _transferToVault(_amount);
    }

    function _withdrawAll() internal {
        // No-op as we don't deposit
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        IERC20Upgradeable(want).transfer(want, (_amount * lossBps) / MAX_BPS);
        return _amount;
    }

    function _transferToVault(uint256 _amount) internal {
        if (_amount > 0) {
            IERC20Upgradeable(want).transfer(vault, _amount);
        }
    }

    function earn() external override {}

    function emitNonProtectedToken(address _token) external override {
        IERC20Upgradeable(_token).transfer(
            vault,
            IERC20Upgradeable(_token).balanceOf(address(this))
        );
        IVault(vault).reportAdditionalToken(_token);
    }

    function tend() external override returns (TokenAmount[] memory tended) {
        tended = new TokenAmount[](1);
        tended[0] = TokenAmount(want, 0);
        return tended;
    }

    function balanceOfPool() public view override returns (uint256) {
        return 0;
    }

    function balanceOfRewards()
        external
        view
        override
        returns (TokenAmount[] memory rewards)
    {
        uint8 len = 1;
        if (testRewardToken != address(0)) {
            len = 2;
        }
        rewards = new TokenAmount[](len);
        rewards[0] = TokenAmount(want, 0);
        if (testRewardToken != address(0)) {
            rewards[1] = TokenAmount(testRewardToken, 0);
        }
        return rewards;
    }

    function harvest()
        external
        override
        returns (TokenAmount[] memory harvested)
    {
        require(msg.sender == governance, "Only governance can harvest");
        uint8 len = 1;
        if (testRewardToken != address(0)) {
            len = 2;
        }
        harvested = new TokenAmount[](len);
        harvested[0] = TokenAmount(want, 14 * 10**18);
        if (testRewardToken != address(0)) {
            harvested[1] = TokenAmount(testRewardToken, 8 * 10**18);
        }
        return harvested;
    }

    function withdrawOther(address _asset) external override {
        IERC20Upgradeable(_asset).transfer(
            vault,
            IERC20Upgradeable(_asset).balanceOf(address(this))
        );
    }
}
