// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IStrategy.sol";

contract ChadgerRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MAX_BPS = 10_000;

    address public governance;
    address public priceCalculator;

    address private vaultImplementation;

    EnumerableSet.AddressSet private strategists;
    mapping(address => EnumerableSet.AddressSet) private vaults;

    event NewVault(address author, address vault);
    struct TokenAmount {
        address token;
        uint256 amount;
    }
    struct TokenApr {
        address token;
        uint256 apr;
    }

    struct VaultData {
        address vault;
        address strategist;
        address strategy;
        string name;
        string version;
        address tokenAddress;
        string tokenName;
        uint256 performanceFeeGovernance;
        uint256 performanceFeeStrategist;
        uint256 withdrawalFee;
        uint256 managementFee;
        uint256 lastHarvestedAt;
        uint256 tvl;
        uint256 tvlInUSD;
        TokenApr[] apr;
    }

    function initialize(
        address _governance,
        address _vaultImplementation,
        address _priceCalculator
    ) public {
        require(governance == address(0));
        governance = _governance;
        vaultImplementation = _vaultImplementation;
        priceCalculator = _priceCalculator;
    }

    function setVaultImplementation(address _vaultImplementation) public {
        require(msg.sender == governance, "!gov");
        vaultImplementation = _vaultImplementation;
    }

    function setPriceCalculator(address _priceCalculator) public {
        require(msg.sender == governance, "!gov");
        priceCalculator = _priceCalculator;
    }

    function setGovernance(address _newGov) public {
        require(msg.sender == governance, "!gov");
        governance = _newGov;
    }

    function registerVault(
        address _token,
        address _keeper,
        address _guardian,
        address _treasury,
        address _badgerTree,
        string memory _name,
        string memory _symbol,
        uint256[4] memory _feeConfig
    ) public returns (address) {
        require(
            vaultImplementation != address(0),
            "vault implement not set yet"
        );
        address vault = Clones.clone(vaultImplementation);
        address user = msg.sender;
        IVault(vault).initialize(
            _token,
            user,
            _keeper,
            _guardian,
            _treasury,
            user,
            _badgerTree,
            _name,
            _symbol,
            _feeConfig
        );
        bool strategistAdded = strategists.add(user);
        bool vaultAdded = vaults[user].add(vault);
        if (vaultAdded) {
            emit NewVault(user, vault);
        }
        return vault;
    }

    function getStrategists() public view returns (address[] memory) {
        uint256 length = strategists.length();
        address[] memory list = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = strategists.at(i);
        }
        return list;
    }

    function getStrategistVaults(address _strategist)
        public
        view
        returns (address[] memory)
    {
        uint256 length = vaults[_strategist].length();
        address[] memory list = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = vaults[_strategist].at(i);
        }
        return list;
    }

    function getVaultData(address _vault, TokenAmount[] memory simulatedYields)
        public
        view
        returns (VaultData memory vaultData)
    {
        IVault vault = IVault(_vault);
        vaultData.vault = _vault;
        vaultData.tokenAddress = vault.token();
        vaultData.tvl = vault.balance();
        vaultData.tvlInUSD = amountInUSD(
            TokenAmount(vaultData.tokenAddress, vaultData.tvl)
        );
        vaultData.strategist = vault.strategist();
        vaultData.strategy = vault.strategy();

        IStrategy.TokenAmount[] memory balanceOfRewards = IStrategy(
            vaultData.strategy
        ).balanceOfRewards();
        vaultData.name = vault.name();
        vaultData.version = vault.version();
        vaultData.tokenName = ERC20(vaultData.tokenAddress).name();
        vaultData.performanceFeeGovernance = vault.performanceFeeGovernance();
        vaultData.performanceFeeStrategist = vault.performanceFeeStrategist();
        vaultData.withdrawalFee = vault.withdrawalFee();
        vaultData.managementFee = vault.managementFee();
        vaultData.lastHarvestedAt = vault.lastHarvestedAt();

        vaultData.apr = getTokensAPR(
            simulatedYields,
            vaultData.lastHarvestedAt,
            vaultData.tvlInUSD
        );
    }

    function getVaultDepositorData(address _vault, address depositor)
        public
        view
        returns (uint256 deposits, uint256 depositsInUSD)
    {
        IVault vault = IVault(_vault);
        address tokenAddress = vault.token();
        uint256 pricePerShare = vault.getPricePerFullShare();
        uint256 depositorShare = vault.balanceOf(depositor);
        deposits = (pricePerShare * depositorShare) / 1e18;
        depositsInUSD = amountInUSD(TokenAmount(tokenAddress, deposits));
    }

    function amountInUSD(TokenAmount memory tokenAmount)
        public
        view
        returns (uint256 amount)
    {
        require(priceCalculator != address(0), "priceCalculator not set yet");
        if (tokenAmount.amount == 0) {
            return 0;
        } else {
            amount = IPriceCalculator(priceCalculator).tokenPriceInUSD(
                tokenAmount.token,
                tokenAmount.amount
            );
        }
    }

    function getTokensAPR(
        TokenAmount[] memory _simulatedYields,
        uint256 _lastHarvestedAt,
        uint256 tvlInUSD
    ) public view returns (TokenApr[] memory apr) {
        apr = new TokenApr[](_simulatedYields.length);
        for (uint256 i = 0; i < _simulatedYields.length; i++) {
            apr[i].token = _simulatedYields[i].token;
            if (tvlInUSD == 0) {
                apr[i].apr = 0;
            } else {
                apr[i].apr = calculateAPR(
                    amountInUSD(_simulatedYields[i]),
                    _lastHarvestedAt,
                    tvlInUSD
                );
            }
        }
    }

    function calculateAPR(
        uint256 reward,
        uint256 _lastHarvestedAt,
        uint256 tvlInUSD
    ) internal view returns (uint256 apr) {
        require(tvlInUSD > 0, "tvlInUSD <= 0");
        require(block.timestamp > _lastHarvestedAt, "!invalid lastHarvestedAt");
        apr =
            (reward *
                MAX_BPS *
                (365 days / (block.timestamp - _lastHarvestedAt))) /
            tvlInUSD;
    }
}
