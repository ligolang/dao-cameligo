#import "./errors.mligo" "Errors"

type owner = address
type amount_ = nat
type t = (owner, amount_) big_map

let get_for_user (vault, owner: t * owner) : amount_ =
    match Big_map.find_opt owner vault with
        Some (tokens) -> tokens
        | None -> 0n

let get_for_user_exn (vault, owner: t * owner) : amount_ =
    let amount_ = get_for_user(vault, owner) in
    if (amount_ = 0n)
        then failwith Errors.no_locked_tokens
        else amount_

let update_for_user (vault, owner, amount_ : t * owner * nat) : t =
    Big_map.update owner (Some amount_) vault
