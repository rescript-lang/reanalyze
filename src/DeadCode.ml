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

let processCmt ~cmtFilePath (cmt_infos : Cmt_format.cmt_infos) =
  (match cmt_infos.cmt_annots with
  | Interface signature ->
    ProcessDeadAnnotations.signature signature;
    setSignatureValueFilter ~fileName:cmt_infos.cmt_sourcefile
      ~moduleTypeRanges:
        (signature.sig_items
        |> List.filter_map (fun (item : Typedtree.signature_item) ->
               match item.sig_desc with
               | Tsig_modtype _ -> Some item.sig_loc
               | _ -> None));
    processSignature ~doValues:true ~doTypes:true signature.sig_type
  | Implementation structure ->
    let cmtiExists =
      Sys.file_exists ((cmtFilePath |> Filename.remove_extension) ^ ".cmti")
    in
    ProcessDeadAnnotations.structure ~doGenType:(not cmtiExists) structure;
    setSignatureValueFilter ~fileName:cmt_infos.cmt_sourcefile
      ~moduleTypeRanges:
        (structure.str_items
        |> List.filter_map (fun (item : Typedtree.structure_item) ->
               match item.str_desc with
               | Tstr_modtype _ -> Some item.str_loc
               | _ -> None));
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
