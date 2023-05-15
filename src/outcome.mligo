#import "./proposal.mligo" "Proposal"
#import "./vote.mligo" "Vote"
#import "./errors.mligo" "Errors"
// #import "./outcome.mligo" "Outcome"

type rejected_state_extra = WithRefund | WithoutRefund
type state = Accepted | Rejected_ of rejected_state_extra | Executed | Canceled

type t = (Proposal.t * state)

type execute_params =
    [@layout:comb]
    {
        outcome_key: nat;
        packed: bytes;
        // ^ the packed Lambda.t
    }

let make (
    p,
    total_supply,
    refund_threshold,
    quorum_threshold,
    super_majority
    : Proposal.t * nat * nat * nat * nat
) : t =
    let (total, for_, against) = Vote.count(p.votes) in
    let state = (if ((total / total_supply * 100n) < refund_threshold)
        then Rejected_(WithoutRefund)
        else if ((for_ / total * 100n) < super_majority)
            || ((total / total_supply * 100n) < quorum_threshold)
        then Rejected_(WithRefund)
        else if for_ > against then (Accepted : state) else Rejected_(WithRefund)) in
    (p, state)

let get_executable_proposal(outcome : t) : Proposal.t =
    match outcome with
        (proposal, Accepted) -> proposal
        | (_,_) -> (failwith Errors.not_executable : Proposal.t)
