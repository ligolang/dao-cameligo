# Specification

## Workflow

![workflow](./images/workflow.png)

The contract is using locked tokens of the configured
***governance_token*** as voting power.  
The potential incentives to lock tokens (outside of getting voting power) is
uncovered.

## Propose

A token owner can *propose* a vote by supplying a ***description_link***,
and an optional hash.  
As SPAM protection mechanism, the configured ***deposit_amount*** of tokens is
transferred from the owner to the DAO. This amount will be sent back to
the proposal creator if configured ***refund_threshold*** participation is
reached by the end of the vote.

```mermaid
sequenceDiagram
  participant Creator
  participant DAO
  participant Token
  Creator->>DAO: propose(description_link,hash option)
  DAO->>Token: transfer(creator,DAO,deposit)
```

## Lock / Vote

To convert their tokens to voting power, owners can *lock* them.
The lock mechanism consists in a transfer from the owner to the DAO contract address,
and tracking the balance of locked tokens in the storage.
Locking can only be done outside ***voting periods***.

After a configured ***start_delay*** elapsed time, token owners can *vote*
during a configured ***voting_period***. Token owners can vote on the proposal,
having their locked tokens being counted as voting power.

```mermaid
sequenceDiagram
  participant Owner
  participant DAO
  participant Token
  Note left of Owner: not voting period
  Owner->>DAO: lock(amount)
  DAO->>Token: transfer(owner,DAO,amount)
  Note left of Owner: voting period
  Owner->>DAO: vote(choice)
```

## End_vote

After the ***voting_period*** has elapsed, anyone can *end_vote*.
The vote result is computed, according to configured ***quorum_threshold***
and ***super_majority***, either the proposal is ***Accepted***,
and a timelock is created, or the proposal is **Rejected**.
When Rejected, The ***deposit_amount*** is either sent back to the proposal
creator or burned if the ***quorum_threshold*** haven't been met.

```mermaid
sequenceDiagram
  participant Any
  participant DAO
  Note left of Any: not voting period
  Any->>DAO: end_vote()
  DAO->>Token: transfer(DAO,creator or burn, deposit)
```

## Release

Token owners can also *release* their tokens, then the DAO contract
transfers locked token and updates the vault balance. Releasing can only be done
outside ***voting periods***.

```mermaid
sequenceDiagram
  participant Owner
  participant DAO
  participant Token
  Note left of Owner: not voting period
  Owner->>DAO: lock(amount)
  DAO->>Token: transfer(owner,DAO,amount)
  Note left of Owner: not voting period
  Owner->>DAO: release(amount)
  DAO->>Token: transfer(DAO,owner,amount)
```

## Cancel

The proposal creator can *cancel* the proposal outside the ***voting_period***
or the ***timelock_period***. The ***deposit_amount*** is burned.

```mermaid
sequenceDiagram
  participant Creator
  participant DAO
  participant Token
  Note left of Creator: not voting period or timelock period
  Creator->>DAO: cancel()
  DAO->>Token: transfer(DAO,burn,deposit)
```

### Execute

After a ***timelock_delay*** and for a ***timelock_period***, anyone can *execute*
a given lambda if it matches the hash associated to the proposal.

```mermaid
sequenceDiagram
  participant Any
  participant DAO
  Note left of Any: timelock period
  Any->>DAO: execute(outcome_key,packed)
```
