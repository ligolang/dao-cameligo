type choice = bool
type t = (choice * nat)
type votes = (address, t) map

(**
    [count (votes)] is the count of [votes].
    Returns a triple of:
        - total votes (for + against),
        - sum of votes for,
        - sum of votes against.
*)
let count (votes : votes) : (nat * nat * nat) =
  let sum =
    fun ((for_, against), (_, (choice, nb)) : (nat * nat) * (address * (t))) ->
      if choice
      then (for_ + nb, against)
      else (for_, against + nb) in
  let (for_, against) = Map.fold sum votes (0n, 0n) in
  (for_ + against, for_, against)
