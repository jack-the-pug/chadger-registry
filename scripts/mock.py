
from multiprocessing.reduction import register
import click
from brownie import ChadgerRegistry, web3, interface, accounts, network, interface, MockStrategy


def connect_account():
    click.echo(f"You are using the '{network.show_active()}' network")
    dev = accounts.load(click.prompt(
        "Account", type=click.Choice(accounts.load())))
    click.echo(f"You are using: 'dev' [{dev.address}]")
    return dev

# mock vault data for UI test
def main():
    dev = connect_account()
    # rinkeby
    registryAddr = ''
    tokenAddr = ''
    token2Addr = ''
    # kovan
    if network.show_active() == "kovan":
        registryAddr = '0x7A809E2F2086CB09E80dFBA533Fc4b2741923EEB'
        tokenAddr = '0xe3d8286716F7c96b6ACbD04225831a539E568e87'
        token2Addr = '0xb03A63621631f215e82470C76D08bbD786514A09'

    registry = ChadgerRegistry.at(registryAddr)
    token = interface.ERC20(tokenAddr)

    tx = registry.registerVault(
        token,
        dev,
        dev,
        dev,
        dev,
        "BTC-USDT",
        "BTC-USDT",
        [
            1000,
            1000,
            20,
            20,
        ], {"from": dev}
    )
    vaultAddr = str(tx.events["NewVault"][0]["vault"])
    click.echo(f"New Vault deployed [{vaultAddr}]")
    strategy = MockStrategy.deploy({"from": dev})
    strategy.setTestRewardToken(token2Addr, {"from": dev})
    vault = interface.IVault(vaultAddr)
    vault.setStrategy(strategy, {"from": dev})
    strategy.initialize(vaultAddr, tokenAddr, dev, {"from": dev})
    token.approve(vaultAddr, 10**22, {"from": dev})
    vault.deposit(20*10**18, {"from": dev})
