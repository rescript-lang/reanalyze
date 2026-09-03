open DeadCommon

let processSignature ~doValues ~doTypes (signature : Types.signature) =
  signature
  |> List.iter (fun sig_item ->
         DeadValue.processSignatureItem ~doValues ~doTypes
           ~moduleLoc:Location.none
           ~path:[!Common.currentModuleName]
           sig_item)

(* Restrict the declarations taken from a file's signature to definitions of
   the file itself, see [DeadValue.setSignatureValueFilter]. *)
let setSignatureValueFilter ~(fileName : string option) ~moduleTypeRanges =
  match fileName with
  | Some fileName -> DeadValue.setSignatureValueFilter ~fileName ~moduleTypeRanges
  | None -> DeadValue.isSignatureValueDeclaration := fun _ -> true

(* Locations of every [module type] declaration of a file, at any depth. *)
let rec moduleTypeRangesOfStructure (structure : Typedtree.structure) =
  structure.str_items
  |> List.concat_map (fun (item : Typedtree.structure_item) ->
         match item.str_desc with
         | Tstr_modtype _ -> [item.str_loc]
         | Tstr_module mb -> moduleTypeRangesOfModuleExpr mb.mb_expr
         | Tstr_recmodule mbs ->
           mbs
           |> List.concat_map (fun (mb : Typedtree.module_binding) ->
                  moduleTypeRangesOfModuleExpr mb.mb_expr)
         | Tstr_include {incl_mod} -> moduleTypeRangesOfModuleExpr incl_mod
         | _ -> [])

and moduleTypeRangesOfModuleExpr (moduleExpr : Typedtree.module_expr) =
  match moduleExpr.mod_desc with
  | Tmod_structure structure -> moduleTypeRangesOfStructure structure
  | Tmod_constraint (inner, _, _, _) -> moduleTypeRangesOfModuleExpr inner
  | Tmod_functor (_, body) -> moduleTypeRangesOfModuleExpr body
  | _ -> []

let rec moduleTypeRangesOfSignature (signature : Typedtree.signature) =
  signature.sig_items
  |> List.concat_map (fun (item : Typedtree.signature_item) ->
         match item.sig_desc with
         | Tsig_modtype _ -> [item.sig_loc]
         | Tsig_module md -> moduleTypeRangesOfModuleType md.md_type
         | Tsig_recmodule mds ->
           mds
           |> List.concat_map (fun (md : Typedtree.module_declaration) ->
                  moduleTypeRangesOfModuleType md.md_type)
         | Tsig_include {incl_mod} -> moduleTypeRangesOfModuleType incl_mod
         | _ -> [])

and moduleTypeRangesOfModuleType (moduleType : Typedtree.module_type) =
  match moduleType.mty_desc with
  | Tmty_signature signature -> moduleTypeRangesOfSignature signature
  | Tmty_functor (_, body) -> moduleTypeRangesOfModuleType body
  | Tmty_with (base, constraints) ->
    (* A [with module type S = sig ... end] constraint carries a module type
       whose items must not count as declarations either. *)
    moduleTypeRangesOfModuleType base
    @ (constraints
      |> List.concat_map (fun (_, _, (constraint_ : Typedtree.with_constraint)) ->
             match constraint_ with
             | Twith_modtype mty | Twith_modtypesubst mty ->
               mty.mty_loc :: moduleTypeRangesOfModuleType mty
             | _ -> []))
  | _ -> []

let processCmt ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
  (match cmt_infos.cmt_annots with
  | Interface signature ->
    ProcessDeadAnnotations.signature signature;
    setSignatureValueFilter ~fileName:cmt_infos.cmt_sourcefile
      ~moduleTypeRanges:(moduleTypeRangesOfSignature signature);
    processSignature ~doValues:true ~doTypes:true signature.sig_type
  | Implementation structure ->
    let cmtiExists =
      Sys.file_exists ((cmtFilePath |> Filename.remove_extension) ^ ".cmti")
    in
    ProcessDeadAnnotations.structure ~doGenType:(not cmtiExists) structure;
    setSignatureValueFilter ~fileName:cmt_infos.cmt_sourcefile
      ~moduleTypeRanges:(moduleTypeRangesOfStructure structure);
    processSignature ~doValues:true ~doTypes:false structure.str_type;
    let doExternals =
      (* This is already handled at the interface level, avoid issues in inconsistent locations
         https://github.com/BuckleScript/syntax/pull/54
         Ideally, the handling should be less location-based, just like other language aspects. *)
      false
    in
    let cmt_value_dependencies =
      Compat.extractValueDependencies ~cmtFilePath cmt_infos
    in
    let cmt_ident_resolutions =
      Compat.resolveIdentOccurrences ~cmtFilePath cmt_infos
    in
    DeadValue.processStructure ~doTypes:true ~doExternals
      ~cmt_value_dependencies ~cmt_ident_resolutions structure
  | _ -> ());
  DeadType.TypeDependencies.forceDelayedItems ();
  DeadType.TypeDependencies.clear ()
