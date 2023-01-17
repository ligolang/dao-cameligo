#import "./config.mligo" "Config"
#import "./lambda.mligo" "Lambda"
#import "./metadata.mligo" "Metadata"
#import "./outcome.mligo" "Outcome"
#import "./proposal.mligo" "Proposal"
#import "./timelock.mligo" "Timelock"
#import "./token.mligo" "Token"
#import "./vault.mligo" "Vault"
#import "./vote.mligo" "Vote"

type outcomes = (nat, Outcome.t) big_map

type t =
    [@layout:comb]
    {
        metadata: Metadata.t;
        governance_token: Token.t;
        config: Config.t;
        vault: Vault.t;
        proposal: Proposal.t option;
        outcomes: outcomes;
        next_outcome_id: nat;
    }

let create_proposal (p, s : Proposal.t * t) : t =
    { s with proposal = Some(p) }

let update_config (f, s : Lambda.parameter_change * t) : t =
    { s with config = f() }

let update_vault (v, s : Vault.t * t) : t =
    { s with vault = v }

let update_votes (p, v, s : Proposal.t * Vote.t * t) : t =
    let new_votes = Map.update (Tezos.get_sender()) (Some(v)) p.votes in
    let new_proposal = { p with votes = new_votes } in
    { s with proposal = Some(new_proposal) }

let update_outcome (k, o, s : nat * Outcome.t * t) : t =
    { s with outcomes = Big_map.update k (Some(o)) s.outcomes }

let add_outcome (o, s : Outcome.t * t) : t =
    let (proposal, status) = o in
    let proposal = (match status with
        (* If proposal is accepted, also create timelock *)
        Accepted -> let unlock_at = Tezos.get_now() + int(s.config.timelock_delay) in
            { proposal with timelock = Some(Timelock.make(
                unlock_at,
                s.config.timelock_period)
            )}
        | _ -> proposal)
    in
    { s with
        proposal = (None : Proposal.t option);
        outcomes = Big_map.update s.next_outcome_id (Some(proposal, status)) s.outcomes;
        next_outcome_id = s.next_outcome_id + 1n
    }


let metadata () : Metadata.t = (Big_map.empty : Metadata.t) |> Big_map.add "" 0x00 |> Big_map.add "contents" 0x7b226e616d65223a2244414f204578616d706c65222c226465736372697074696f6e223a22416e204578616d706c652044414f20436f6e7472616374222c2276657273696f6e223a22312e302e30222c226c6963656e7365223a7b226e616d65223a224d4954227d2c22617574686f7273223a5b22736d6172742d636861696e203c74657a6f7340736d6172742d636861696e2e66723e225d2c22686f6d6570616765223a2268747470733a2f2f6769746875622e636f6d2f6c69676f6c616e672f64616f2d63616d656c69676f222c22736f75726365223a7b22746f6f6c73223a2263616d656c69676f222c226c6f636174696f6e223a2268747470733a2f2f6769746875622e636f6d2f6c69676f6c616e672f64616f2d63616d656c69676f2f737263227d2c22696e7465726661636573223a5b22545a49502d303136225d7d

let initial : t =
  {metadata = metadata ();
   governance_token = ("KT1AuAxBeB8sh17HhxK5iD8FGGgUQbnhG4m5" : address);
   config =
     {deposit_amount = 4n;
      refund_threshold = 32n;
      quorum_threshold = 67n;
      super_majority = 80n;
      start_delay = 86400n;
      voting_period = 604800n;
      timelock_delay = 86400n;
      timelock_period = 259200n;
      burn_address = ("KT1CZMurPAjSfZqcn6LBUNUhG4byE6AJgDT6" : address)};
   vault = (Big_map.empty : Vault.t);
   proposal = None;
   outcomes = (Big_map.empty : outcomes);
   next_outcome_id = 1n}
