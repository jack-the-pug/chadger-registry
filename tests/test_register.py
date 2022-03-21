from brownie import (
    interface,
    MockStrategy,
    chain,
)


def test_user_can_register_vault(user2, registry, user1, token1, token2, keeper, guardian, treasury, badgerTree):
    performanceFeeGovernance = 1000
    performanceFeeStrategist = 1000
    withdrawalFee = 50
    managementFee = 50
    tx = registry.registerVault(
        token1,
        keeper,
        guardian,
        treasury,
        badgerTree,
        "Vault",
        "VAULT",
        [
            performanceFeeGovernance,
            performanceFeeStrategist,
            withdrawalFee,
            managementFee,
        ], {"from": user1}
    )

    strategists = registry.getStrategists()
    assert len(strategists) == 1
    assert strategists[0] == user1
    event = tx.events["NewVault"][0]
    assert event["author"] == user1

    user1Vaults = registry.getStrategistVaults(user1)
    assert len(user1Vaults) == 1
    user1Vault = interface.IVault(user1Vaults[0])
    assert user1Vault.strategist() == user1
    assert user1Vault.governance() == user1

    strategy = MockStrategy.deploy({"from": user1})
    strategy.setTestRewardToken(token2, {"from": user1})
    user1Vault.setStrategy(strategy, {"from": user1})
    strategy.initialize(user1Vault, token1, user1, {"from": user1})
    user1Deposits = 1000000
    user2Deposits = 2000000
    token1.approve(user1Vault.address, user1Deposits, {"from": user1})
    user1Vault.deposit(user1Deposits, {"from": user1})
    token1.approve(user1Vault.address, user2Deposits, {"from": user2})
    user1Vault.deposit(user2Deposits, {"from": user2})
    chain.sleep(10000)
    
    tx = strategy.harvest({"from": user1})
    yields = tx.return_value
    # harvest amounts were hard code in `MockStrategy.harvest`
    assert yields[0][0] == token1
    assert yields[0][1] == 14 * 10**18
    assert yields[1][0] == token2
    assert yields[1][1] == 8 * 10**18
    (vaultAddr, strategist, strategyAddr, name, version, tokenAddress, tokenName, _performanceFeeGovernance, _performanceFeeStrategist,
     _withdrawalFee, _managementFee, lastHarvestedAt, tvl, _tvlInUSD, apr) = registry.getVaultData(user1Vault, yields)
    assert apr[0][0] == token1
    assert apr[0][1] > 0
    assert apr[1][0] == token2
    assert apr[1][1] > 0
    assert strategist == user1
    assert strategyAddr == strategy.address
    assert name == "Vault"
    assert version == "1.5"
    assert tokenName == "Wrapped BTC"
    assert vaultAddr == user1Vault.address
    assert tvl == user1Deposits + user2Deposits
    assert tokenAddress == token1

    (deposits, depositsInUSD) = registry.getVaultDepositorData(user1Vault, user1)
    assert deposits == user1Deposits
    assert depositsInUSD == user1Deposits
    (deposits, depositsInUSD) = registry.getVaultDepositorData(user1Vault, user2)
    assert deposits == user2Deposits
    assert depositsInUSD == user2Deposits
