# Miki

## Get started

### Install dependencies

```sh
cd miki
yarn install
```

### Set environment variables

```sh
cp .env.example .env
```

Set the respective environment variables;

`API_KEY_{Arbitrary Network}`: API key to verify the contract when deployed

`API_KEY_INFURA`: API key for Infura's rpc endpoint

`PRIVATE_KEY`: Private key to send transaction

## Usage

### Build

Build the contracts:

```sh
yarn build
```

### Clean

Delete the build artifacts and cache directories:

```sh
yarn clean
```

### Coverage

Get a test coverage report:

```sh
yarn coverage
```

### Deploy

Deploy to Arbitrum Sepolia, Base Sepolia and Optimism Sepolia:

```sh
yarn deploy base_sepolia optimism_sepolia
```

For this script to work, you need to have a PRIVATE_KEY environment variable in `.env`.

### Format

Format the contracts:

```sh
yarn format
```

### Gas Usage

Get a gas report:

```sh
forge test --gas-report
```

### Lint

Lint the contracts:

```sh
yarn lint
```

### Test

Run the tests:

```sh
yarn test
```

## Send transaction

### Deposit ETH

You can specify any amount to deposit ETH;

```sh
yarn deposit <Amount>
```

### Withdraw ETH

You can specify any amount to withdraw ETH;

```sh
yarn withdraw <Amount>
```

### Cross-chain mint

You can execute cross-chain mint with any chain id and any receiving address;

```sh
yarn cross-chain-mint <Dstination chain id> <Recipient address>
```

### Cross-chain Deposit to AAVE

You can execute cross-chain deposit to aave lending pool with any chain id and any amount;

```sh
yarn cross-chain-deposit <Dstination chain id> <Amount>
```
