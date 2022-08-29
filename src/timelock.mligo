#import "./errors.mligo" "Errors"

type t =
    [@layout:comb]
    {
        unlock_at: timestamp;
        (* ^ timestamp for the unlock to happen *)

        relock_at: timestamp;
        (* ^ timestamp for the relock to happen *)
    }

let make (unlock_at, timelock_period : timestamp * nat) : t =
    {
       unlock_at = unlock_at;
       relock_at = unlock_at + int(timelock_period);
    }

let is_locked (t : t) = ((Tezos.get_now() < t.unlock_at) || (Tezos.get_now() >= t.relock_at))

let _check_unlocked (t_opt : t option) =
    match t_opt with
        None -> failwith Errors.timelock_not_found
        | Some(t) -> assert_with_error
            (not is_locked(t))
            Errors.timelock_locked

let _check_locked (t_opt : t option) =
    match t_opt with
        None -> failwith Errors.timelock_not_found
        | Some(t) -> assert_with_error
            (is_locked(t))
            Errors.timelock_unlocked
