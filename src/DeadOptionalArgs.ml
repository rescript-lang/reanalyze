open DeadCommon
open Common

let active () = true

type item = {
  posTo : Lexing.position;
  posToImpl : Lexing.position option;
      (** Shape-resolved implementation, used when [posTo] is not a declaration. *)
  forwardable : bool;
      (** Whether the call may be attributed to the implementations of a module
          type item. False for calls through a functor parameter, which are
          credited at application sites. *)
  argNames : string list;
  argNamesMaybe : string list;
}

let delayedItems = (ref [] : item list ref)
let functionReferences = (ref [] : (Lexing.position * Lexing.position) list ref)

let addFunctionReference ~(locFrom : Location.t) ~(locTo : Location.t) =
  if active () then
    let posTo = locTo.loc_start in
    let posFrom = locFrom.loc_start in
    let shouldAdd =
      match PosHash.find_opt decls posTo with
      | Some {declKind = Value {optionalArgs}} ->
        not (OptionalArgs.isEmpty optionalArgs)
      | _ -> false
    in
    if shouldAdd then (
      if !Common.Cli.debug then
        Log_.item "OptionalArgs.addFunctionReference %s %s@."
          (posFrom |> posToString) (posTo |> posToString);
      functionReferences := (posFrom, posTo) :: !functionReferences)

let rec hasOptionalArgs (texpr : Types.type_expr) =
  match Compat.get_desc texpr with
  | _ when not (active ()) -> false
  | Tarrow (Optional _, _tFrom, _tTo, _) -> true
  | Tarrow (_, _tFrom, tTo, _) -> hasOptionalArgs tTo
  | Tlink t -> hasOptionalArgs t
  | Tsubst _ -> hasOptionalArgs (Compat.getTSubst (Compat.get_desc texpr))
  | _ -> false

let rec fromTypeExpr (texpr : Types.type_expr) =
  match Compat.get_desc texpr with
  | _ when not (active ()) -> []
  | Tarrow (Optional s, _tFrom, tTo, _) -> s :: fromTypeExpr tTo
  | Tarrow (_, _tFrom, tTo, _) -> fromTypeExpr tTo
  | Tlink t -> fromTypeExpr t
  | Tsubst _ -> fromTypeExpr (Compat.getTSubst (Compat.get_desc texpr))
  | _ -> []

let addReferences ~(locFrom : Location.t) ~(locTo : Location.t)
    ?(locToImpl : Location.t option) ?(forwardable = true) ~path
    (argNames, argNamesMaybe) =
  if active () then (
    let posTo = locTo.loc_start in
    let posToImpl = Option.map (fun (l : Location.t) -> l.loc_start) locToImpl in
    let posFrom = locFrom.loc_start in
    delayedItems :=
      {posTo; posToImpl; forwardable; argNames; argNamesMaybe} :: !delayedItems;
    if !Common.Cli.debug then
      Log_.item
        "DeadOptionalArgs.addReferences %s called with optional argNames:%s \
         argNamesMaybe:%s %s@."
        (path |> Path.fromPathT |> Path.toString)
        (argNames |> String.concat ", ")
        (argNamesMaybe |> String.concat ", ")
        (posFrom |> posToString))

(* A call through a functor parameter, credited to the implementation the
   functor was applied to. When [posTo] could only be resolved to a module
   type item rather than a declaration (no shapes, e.g. before OCaml 5.3, or
   an argument without a resolvable shape), the call is forwarded to the
   implementations of that item, conservatively. *)
let addCallToImplementation ~(posTo : Lexing.position) (argNames, argNamesMaybe)
    =
  if active () then
    delayedItems :=
      {posTo; posToImpl = None; forwardable = true; argNames; argNamesMaybe}
      :: !delayedItems

(* Once all declarations are known, calls whose target is not a declaration
   but have a shape-resolved implementation are attributed to it. Must run
   before [forwardDelayedItems] and [forceDelayedItems]. *)
let settleDelayedItems () =
  delayedItems :=
    !delayedItems
    |> List.map (fun item ->
           match (item.posToImpl, PosHash.find_opt decls item.posTo) with
           | Some posToImpl, None -> {item with posTo = posToImpl; posToImpl = None}
           | _ -> item)

(* Calls recorded against a signature item that is not a declaration (e.g. a
   [val] inside a named module type) are re-attributed to the implementation.
   Must run before [forceDelayedItems]. *)
let forwardDelayedItems ~(posFrom : Lexing.position) ~(posTo : Lexing.position)
    =
  let forwarded =
    !delayedItems
    |> List.filter_map (fun item ->
           if item.forwardable && item.posTo = posFrom then
             Some {item with posTo}
           else None)
  in
  delayedItems := forwarded @ !delayedItems

let forceDelayedItems () =
  let items = !delayedItems |> List.rev in
  delayedItems := [];
  items
  |> List.iter (fun {posTo; argNames; argNamesMaybe} ->
         match PosHash.find_opt decls posTo with
         | Some {declKind = Value r} ->
           r.optionalArgs |> OptionalArgs.call ~argNames ~argNamesMaybe
         | _ -> ());
  let fRefs = !functionReferences |> List.rev in
  functionReferences := [];
  fRefs
  |> List.iter (fun (posFrom, posTo) ->
         match
           (PosHash.find_opt decls posFrom, PosHash.find_opt decls posTo)
         with
         | Some {declKind = Value rFrom}, Some {declKind = Value rTo} ->
           OptionalArgs.combine rFrom.optionalArgs rTo.optionalArgs
         | _ -> ())

let check decl =
  match decl with
  | {declKind = Value {optionalArgs}}
    when active ()
         && not (ProcessDeadAnnotations.isAnnotatedGenTypeOrLive decl.pos) ->
    optionalArgs
    |> OptionalArgs.iterUnused (fun s ->
           Log_.warning ~loc:(decl |> declGetLoc) ~name:"Warning Unused Argument"
             (fun ppf () ->
               Format.fprintf ppf
                 "optional argument @{<info>%s@} of function @{<info>%s@} is \
                  never used"
                 s
                 (decl.path |> Path.withoutHead)));
    optionalArgs
    |> OptionalArgs.iterAlwaysUsed (fun s nCalls ->
           Log_.warning ~loc:(decl |> declGetLoc)
             ~name:"Warning Redundant Optional Argument" (fun ppf () ->
               Format.fprintf ppf
                 "optional argument @{<info>%s@} of function @{<info>%s@} is \
                  always supplied (%d calls)"
                 s
                 (decl.path |> Path.withoutHead)
                 nCalls))
  | _ -> ()
