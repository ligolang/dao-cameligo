#import "./errors.mligo" "Errors"
#import "./vote.mligo" "Vote"
#import "./timelock.mligo" "Timelock"

type t =
    [@layout:comb]
    {
        description_link: string;
        hash: bytes option;
        start_at: timestamp;
        end_at: timestamp;
        votes: Vote.votes;
        creator: address;
        timelock: Timelock.t option;
    }

type make_params =
    [@layout:comb]
    {
        description_link: string;
        hash: bytes option;
    }

let make (p, start_delay, voting_period : make_params * nat * nat) : t =
    let start_at = Tezos.get_now() + int(start_delay) in
    {
        description_link = p.description_link;
        hash = p.hash;
        start_at = start_at;
        end_at = start_at + int(voting_period);
        votes = (Map.empty: Vote.votes);
        creator = Tezos.get_sender();
        timelock = (None : Timelock.t option);
    }

let is_voting_period (p : t) =
    ((Tezos.get_now() >= p.start_at) && (Tezos.get_now() < p.end_at))

let _check_not_voting_period (p : t) =
    assert_with_error
        (not is_voting_period(p))
        Errors.voting_period

let _check_is_voting_period (p : t) =
    assert_with_error
        (is_voting_period(p))
        Errors.not_voting_period

let _check_no_vote_ongoing (p_opt : t option) =
    match p_opt with
        Some(p) -> _check_not_voting_period(p)
        | None -> ()

let _check_voting_period_ended (p : t) =
    assert_with_error
        (Tezos.get_now() > p.end_at)
        Errors.voting_period
