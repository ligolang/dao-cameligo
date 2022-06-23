# Smart contract data types

The following diagram describes the contract types.  
[Ocaml conventions](https://stackoverflow.com/questions/29363460/whats-the-ocaml-naming-convention-for-constructors)
are followed by trying to have one type per module.

```mermaid
classDiagram
    Timelock <|-- Proposal
    Vote <|-- Proposal
    Proposal <|-- Outcome
    Outcome <|-- Storage
    Vault <|-- Storage
    Token <|-- Storage
    Proposal <|-- Storage
    Config <|-- Storage

    class Vault{
        type t
        get_for_user(t, address) nat
        get_for_user_exn(t, address) nat
        update_for_user(t, address, nat) t
    }

    class Timelock{
        type t
        make(timestamp, nat) t
        is_locked(t) bool
        _check_unlocked(t option) bool
        _check_locked(t option) bool
    }

    class Token{
        type t
        get_transfer_entrypoint(address) (FA2.transfer contract)
        transfer(t, address, address, nat) operation
        get_total_supply(t) nat option
    }

    class Vote{
        type t
        count(votes) (nat * nat *nat)
    }
 
    class Outcome{
        type t
        make(Proposal.t, nat, nat, nat) t
        get_executable_proposal(t) (Proposal.t)
    }

    class Proposal{
        type t
        make()
        is_voting_period(t) bool
        _check_not_voting_period(t) bool
        _check_is_voting_period(t) bool
        _check_no_vote_ongoing(t) bool
        _check_voting_period_ended(t) bool
    }

    class Config{
        type t
    }

    class Storage{
        type t
        initial_storage t
        create_proposal(Proposal.t, t) t
        update_config(Lambda.parameter_change, t) t
        update_vault(Vault.t, t) t
        update_votes(Proposal.t, Vote.t, t) t
        update_outcome(nat, Outcome.t, t) t
        add_outcome(Outcome.t, t) t
    }
```
