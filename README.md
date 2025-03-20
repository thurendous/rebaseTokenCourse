# Cross-chain Rebase Token
1. A protocol that allows user to deposit into a vault and in return, receiver rebaes tokens that represent their underlying balance.
2. Rebase Token -> balanceOf function is dynamic to show the chaging balance with time.
    - Balnace increases linearly with time
    - Mint tokens to our users every time they perform an action (minting, burning, transferring, or .... bridging)
3. Interest rate
    - Individually set an interest rate or each user based on some global interest rate of the protocol at the time the user deposits into the vault. 
    - This global inerest rate can only decrease to incetivise/reward early adopters.
    - increase token adoption!



## Install Openzeppelin
```bash
forge install openzeppelin/openzeppelin-contracts
```



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
