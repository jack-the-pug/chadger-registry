import click
from brownie import (AdminUpgradeabilityProxy,
                     ChadgerRegistry, accounts, network, web3)


def connect_account():
    click.echo(f"You are using the '{network.show_active()}' network")
    dev = accounts.load(click.prompt(
        "Account", type=click.Choice(accounts.load())))
    click.echo(f"You are using: 'dev' [{dev.address}]")
    return dev


proxyAdmin = web3.toChecksumAddress(
    "0xDA25ee226E534d868f0Dd8a459536b03fEE9079b")


def main():
    if click.confirm("Deploy New Registry"):
        dev = connect_account()

        # rinkeby
        priceCalculator = ""
        vaultImplementation = ""
        # kovan
        if network.show_active() == "kovan":
            priceCalculator = "0x897F0e332f5e4EA581C60a6726831B89c5352A8f"
            vaultImplementation = "0x2fB8c7117851f5A9Fb9FDD9A3C66F3D01CaA1223"

        ChadgerRegistry = ChadgerRegistry.deploy({"from": dev})

        args = [dev.address, vaultImplementation, priceCalculator]
        registry_proxy = AdminUpgradeabilityProxy.deploy(
            ChadgerRegistry, proxyAdmin, ChadgerRegistry.initialize.encode_input(*args), {"from": dev})
        AdminUpgradeabilityProxy.remove(registry_proxy)
        registry_proxy = ChadgerRegistry.at(registry_proxy.address)
        print(registry_proxy)
        print(dir(registry_proxy))
        click.echo(f"New Registry Release deployed [{registry_proxy.address}]")

        return registry_proxy
