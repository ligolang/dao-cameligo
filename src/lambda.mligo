#import "./config.mligo" "Config"
#import "./errors.mligo" "Errors"

type parameter_change = (unit -> Config.t)
type operation_list = (unit -> operation list)

type t =
    ParameterChange of parameter_change
    | OperationList of operation_list

let unpack (hash_opt, packed : bytes option * bytes) =
    match hash_opt with
        None -> (failwith Errors.hash_not_found : t)
      | Some hash_ -> let _check_hash =
        assert_with_error
          (hash_ = Crypto.sha256 packed)
          Errors.hash_not_match
      in (match (Bytes.unpack packed : t option) with
        None -> failwith(Errors.unpack_mismatch)
        | Some lambda_ -> lambda_)
