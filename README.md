# DAO-cameligo

A modular example DAO contract on Tezos written in Ligolang.  

## Intro

This example DAO allows FA2 token holders to vote on proposals, which trigger
on-chain changes when accepted.  
It is using **token based quorum voting**, requiring a given threshold of
participating tokens for a proposal to pass.  
The contract code uses Ligo [modules](https://ligolang.org/docs/language-basics/modules/),
and the [tezos-ligo-fa2](https://www.npmjs.com/package/tezos-ligo-fa2)
[package](https://ligolang.org/docs/advanced/package-management).

The used `FA2` token is expected to extend [the TZIP-12 standard](https://tzip.tezosagora.org/proposal/tzip-12/)
with an on-chain view `total_supply` returning the total supply of tokens. This
number, of type `nat` is then used as base for the participation computation,
see [example `FA2` in the test directory](./test/bootstrap/single_asset.mligo).

## Requirements

The contract is written in `cameligo` flavour of [LigoLANG](https://ligolang.org/),
to be able to compile the contract, you need [docker](https://docs.docker.com/engine/install/).

For deploy scripts, you also need to have [nodejs](https://nodejs.org/en/) installed, up to version 14.

## Usage

1. Run `make install` to install dependencies
2. Run `make` to see available commands

## Documentation

See [Documentation](./docs/00-index.md)

## Follow-Up

- Expand vote: add third "Pass" choice, add [Score Voting](https://en.wikipedia.org/wiki/Score_voting)
- Vote incentives with some staking mechanism
- Mutation tests
- Optimizations (inline...)
- Attack tests (see last one: <https://twitter.com/ylv_io/status/1515773148465147926>)
