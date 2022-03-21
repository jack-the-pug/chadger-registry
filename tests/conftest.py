import pytest
from brownie import (
  accounts,
  interface,
  ChadgerRegistry,
  MockPriceCalculator, 
  MockVault,
)

@pytest.fixture
def deployer():
  return accounts[0]

@pytest.fixture
def user1():
  return accounts[1]

@pytest.fixture
def user2():
  return accounts[2]

@pytest.fixture
def keeper():
    return accounts[3]

@pytest.fixture
def guardian():
    return accounts[4]

@pytest.fixture
def treasury():
    return accounts[5]

@pytest.fixture
def badgerTree():
    return accounts[6]

@pytest.fixture
def vaultImplementation(deployer):
   vaultImplementation = MockVault.deploy({"from": deployer})
   return vaultImplementation

@pytest.fixture
def registry(deployer, vaultImplementation):
    registry = ChadgerRegistry.deploy({'from': deployer})
    priceCalculator = MockPriceCalculator.deploy({'from': deployer})
    registry.initialize(deployer, vaultImplementation.address, priceCalculator.address, {"from": deployer})
    yield registry


## Fund the account
@pytest.fixture
def token1(user1, user2):
    WANT = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
    WHALE_ADDRESS = "0xbf72da2bd84c5170618fbe5914b0eca9638d5eb5"
    token = interface.IERC20(WANT)
    whaleBalance = token.balanceOf(accounts.at(WHALE_ADDRESS, force=True))
    token.transfer(user1, whaleBalance / 2, {"from": WHALE_ADDRESS})
    token.transfer(user2, whaleBalance / 2, {"from": WHALE_ADDRESS})
    return token

@pytest.fixture
def token2(user1, user2):
    WETH = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
    WHALE_ADDRESS = "0x2f0b23f53734252bda2277357e97e1517d6b042a"
    token = interface.IERC20(WETH)
    whaleBalance = token.balanceOf(accounts.at(WHALE_ADDRESS, force=True))
    token.transfer(user1, whaleBalance / 2, {"from": WHALE_ADDRESS})
    token.transfer(user2, whaleBalance / 2, {"from": WHALE_ADDRESS})
    return token


## Forces reset before each test
@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass
