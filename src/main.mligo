#import "./constants.mligo" "Constants"
#import "./errors.mligo" "Errors"
#import "./lambda.mligo" "Lambda"
#import "./outcome.mligo" "Outcome"
#import "./proposal.mligo" "Proposal"
#import "./storage.mligo" "Storage"
#import "./vote.mligo" "Vote"
#import "./token.mligo" "Token"
#import "./vault.mligo" "Vault"
#import "./timelock.mligo" "Timelock"

type storage = Storage.t
type result = operation list * storage

[@entry] let execute (p : Outcome.execute_params) (s : storage) : result =
    let { outcome_key; packed } = p in
    let proposal = (match Big_map.find_opt outcome_key s.outcomes with
        None -> failwith Errors.outcome_not_found
        | Some(o) -> Outcome.get_executable_proposal(o)) in

    let () = Timelock._check_unlocked(proposal.timelock) in
    let lambda_ = Lambda.unpack(proposal.hash, packed) in

    match lambda_ with
        OperationList f ->
            f(),
            Storage.update_outcome(outcome_key, (proposal, Executed), s)
        | ParameterChange f ->
            Constants.no_operation,
            Storage.update_outcome(
                outcome_key,
                (proposal, Executed),
                Storage.update_config(f,s)
            )

[@entry] let propose (p : Proposal.make_params) (s : storage) : result =
    match s.proposal with
        Some(_) -> failwith Errors.proposal_already_exists
        | None -> [
            Token.transfer(
                s.governance_token,
                Tezos.get_sender(),
                Tezos.get_self_address(),
                s.config.deposit_amount
        )], Storage.create_proposal(
                Proposal.make(p, s.config.start_delay, s.config.voting_period),
                s)

[@entry] let cancel (outcome_key_opt : nat option) (s : storage) : result =
   [Token.transfer(
        s.governance_token,
        Tezos.get_self_address(),
        s.config.burn_address,
        s.config.deposit_amount)
   ], (match outcome_key_opt with
        None -> (match s.proposal with
            None -> failwith Errors.nothing_to_cancel
            | Some(p) -> let () = Proposal._check_not_voting_period(p) in
                let _check_sender_is_creator = assert_with_error
                    (p.creator = Tezos.get_sender())
                    Errors.not_creator in
                Storage.add_outcome((p, Canceled), s))
        | Some(outcome_key) -> (match Big_map.find_opt outcome_key s.outcomes with
            None -> failwith Errors.outcome_not_found
            | Some(o) -> let (p, state) = o in
            let _check_sender_is_creator = assert_with_error
                (p.creator = Tezos.get_sender())
                Errors.not_creator in
            let _check_not_executed = assert_with_error
                (state <> (Executed : Outcome.state))
                Errors.already_executed in
            let () = Timelock._check_locked(p.timelock) in
            Storage.update_outcome(outcome_key, (p, Canceled), s)))

[@entry] let lock (amount_ : nat) (s : storage) : result =
    let () = Proposal._check_no_vote_ongoing(s.proposal) in
    let current_amount = Vault.get_for_user(s.vault, Tezos.get_sender()) in

    [Token.transfer(
        s.governance_token,
        Tezos.get_sender(),
        Tezos.get_self_address(), amount_)
    ], Storage.update_vault(Vault.update_for_user(
        s.vault,
        Tezos.get_sender(),
        current_amount + amount_), s)

[@entry] let release (amount_ : nat) (s : storage) : result =
    let () = Proposal._check_no_vote_ongoing(s.proposal) in
    let current_amount = Vault.get_for_user_exn(s.vault, Tezos.get_sender()) in
    let _check_balance = assert_with_error
        (current_amount >= amount_)
        Errors.not_enough_balance in

    [Token.transfer(s.governance_token, Tezos.get_self_address(), Tezos.get_sender(), amount_)],
    Storage.update_vault(Vault.update_for_user(
        s.vault,
        Tezos.get_sender(),
        abs(current_amount - amount_)), s)

[@entry] let vote (choice : bool) (s : storage) : result =
    Constants.no_operation, (match s.proposal with
        None -> failwith Errors.no_proposal
        | Some(p) -> let () = Proposal._check_is_voting_period(p) in
            let amount_ = Vault.get_for_user_exn(s.vault, Tezos.get_sender()) in
            Storage.update_votes(p, (choice, amount_), s))

[@entry] let end_vote (_ : unit) (s : storage) : result =
    match s.proposal with
        None -> failwith Errors.no_proposal
        | Some(p) -> let () = Proposal._check_voting_period_ended(p) in
            let total_supply = (match Token.get_total_supply(s.governance_token) with
                None -> failwith Errors.fa2_total_supply_not_found
                | Some n -> n) in
            let outcome = Outcome.make(
                    p,
                    total_supply,
                    s.config.refund_threshold,
                    s.config.quorum_threshold,
                    s.config.super_majority
                ) in
            let (_, state) = outcome in
            let transfer_to_addr = match state with
                Rejected_(WithoutRefund) -> s.config.burn_address
                | _ -> p.creator
            in
            ([Token.transfer(
                s.governance_token,
                Tezos.get_self_address(),
                transfer_to_addr,
                s.config.deposit_amount)]
            ), Storage.add_outcome(outcome, s)
