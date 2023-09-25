#include "@ligo/fa/lib/fa2/asset/single_asset.mligo"

(* Extension of FA2 to be used as governance token of the DAO *)

[@view] let total_supply (_ : unit) (_s : storage) : nat =
    30n
