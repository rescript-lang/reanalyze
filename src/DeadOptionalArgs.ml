open DeadCommon
open Common

let active () = true

type item = {
  posTo : Lexing.position;
  posToImpl : Lexing.position option;
      (** Shape-resolved implementation, used when [posTo] is not a declaration. *)
  argNames : string list;
  argNamesMaybe : string list;
  fromAlias : Lexing.position option;
      (** The partial application that forms this alias ([let p = f ~x:1]):
          a call only when nothing calls through the alias. *)
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

(* Aliases formed by a partial application ([let p = f ~x:1]), by the
   application's location (an operand can start at the same position:
   [let p = h ~y:2 1 |> mk] is typed as [mk (h ~y:2 1)]). *)
let aliasApplications :
    (Lexing.position * Lexing.position, Lexing.position) Hashtbl.t =
  Hashtbl.create 16

let aliasApplication (loc : Location.t) =
  Hashtbl.find_opt aliasApplications (loc.loc_start, loc.loc_end)

let addReferences ~(locFrom : Location.t) ~(locTo : Location.t)
    ?(locToImpl : Location.t option) ~path
    (argNames, argNamesMaybe) =
  if active () then (
    let posTo = locTo.loc_start in
    let posToImpl = Option.map (fun (l : Location.t) -> l.loc_start) locToImpl in
    let posFrom = locFrom.loc_start in
    delayedItems :=
      {posTo; posToImpl; argNames; argNamesMaybe;
       fromAlias = aliasApplication locFrom}
      :: !delayedItems;
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
let addCallToImplementation ~(locFrom : Location.t)
    ~(posTo : Lexing.position) (argNames, argNamesMaybe) =
  if active () then
    delayedItems :=
      {posTo; posToImpl = None; argNames; argNamesMaybe;
       fromAlias = aliasApplication locFrom}
      :: !delayedItems

(* Bindings that alias or partially apply another function ([let g = f],
   [let g = f ~x:1]) do not own optional parameters: calls through them are
   calls of the function they stand for. Each alias maps to its target and
   the optional arguments it passes itself (here supplied [x], maybe none),
   which every call through it passes too. *)
let aliasTargets : (Lexing.position * (string list * string list)) PosHash.t =
  PosHash.create 16

(* The aliases some call goes through. The application forming an alias
   ([application]) is then not a call itself: each call through it is one.
   When no call goes through it (it escapes, or is unused), the application
   counts once, so that what it passes is not reported as never used. *)
let aliasesCalled = ref PosSet.empty

let addAlias ~(application : Location.t option) ~supplied
    ~(posFrom : Lexing.position) ~(posTo : Lexing.position) =
  if posFrom <> posTo then (
    if !Common.Cli.debug then
      Log_.item "OptionalArgs.addAlias %s --> %s@." (posFrom |> posToString)
        (posTo |> posToString);
    application
    |> Option.iter (fun (loc : Location.t) ->
           Hashtbl.replace aliasApplications (loc.loc_start, loc.loc_end)
             posFrom);
    PosHash.replace aliasTargets posFrom (posTo, supplied))

(* The function an alias chain stands for, with the optional arguments the
   chain passes on the way. *)
let rec resolveAliasCall ?(seen = PosSet.empty) pos (argNames, argNamesMaybe)
    =
  match PosHash.find_opt aliasTargets pos with
  | Some (target, (supplied, maybe)) when not (PosSet.mem pos seen) ->
    aliasesCalled := PosSet.add pos !aliasesCalled;
    resolveAliasCall ~seen:(PosSet.add pos seen) target
      (supplied @ argNames, maybe @ argNamesMaybe)
  | _ -> (pos, (argNames, argNamesMaybe))

let isAlias pos = PosHash.mem aliasTargets pos

(* A call through an alias is a call of the function it stands for. *)
let resolveItem item =
  let posTo, (argNames, argNamesMaybe) =
    resolveAliasCall item.posTo (item.argNames, item.argNamesMaybe)
  in
  {item with posTo; argNames; argNamesMaybe}

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
let forwardDelayedItems dependencies =
  (* Aliases are declarations, so they are resolved before the traversal
     stops at them; those declared in an interface are known only now. *)
  delayedItems := List.map resolveItem !delayedItems;
  (* Traverse each original call independently. A diamond or cycle in the
     signature graph must not multiply a call, while distinct calls with the
     same argument labels must remain distinct. Declarations are endpoints:
     ordinary function references handle their optional-argument state. *)
  delayedItems :=
    !delayedItems
    |> List.concat_map (fun item ->
        let rec visit seen pos =
          if PosSet.mem pos seen then seen
          else
            let seen = PosSet.add pos seen in
            if PosHash.mem decls pos then seen
            else
              PosSet.fold
                (fun target seen -> visit seen target)
                (PosHash.findSet dependencies pos)
                seen
        in
        visit PosSet.empty item.posTo
        |> PosSet.elements
        |> List.map (fun posTo -> {item with posTo}))

let forceDelayedItems () =
  (* Forwarding can reach an alias ([let g = f] implementing a [val]). *)
  let items = !delayedItems |> List.rev |> List.map resolveItem in
  delayedItems := [];
  (* Now every call through an alias is known. *)
  let items =
    items
    |> List.filter (fun item ->
           match item.fromAlias with
           | Some alias -> not (PosSet.mem alias !aliasesCalled)
           | None -> true)
  in
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
