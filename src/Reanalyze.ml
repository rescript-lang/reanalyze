open Common

let loadCmtFile ~cmtRoot cmtFilePath =
  let cmt_infos = Cmt_format.read_cmt cmtFilePath in
  let excludePath sourceFile =
    !Cli.excludePaths
    |> List.exists (fun prefix_ ->
           let prefix =
             match Filename.is_relative sourceFile with
             | true -> prefix_
             | false -> Filename.concat (Sys.getcwd ()) prefix_
           in
           String.length prefix <= String.length sourceFile
           &&
           try String.sub sourceFile 0 (String.length prefix) = prefix
           with Invalid_argument _ -> false)
  in
  match FindSourceFile.cmt ?cmtRoot cmt_infos with
  | Some sourceFile when not (excludePath sourceFile) ->
    if !Cli.debug then
      Log_.item "Scanning %s Source:%s@."
        (match !Cli.ci && not (Filename.is_relative cmtFilePath) with
        | true -> Filename.basename cmtFilePath
        | false -> cmtFilePath)
        (match !Cli.ci && not (Filename.is_relative sourceFile) with
        | true -> sourceFile |> Filename.basename
        | false -> sourceFile);
    FileReferences.addFile sourceFile;
    currentSrc := sourceFile;
    currentModule := Paths.getModuleName sourceFile;
    currentModuleName :=
      !currentModule
      |> Name.create ~isInterface:(Filename.check_suffix !currentSrc "i");
    if runConfig.dce then cmt_infos |> DeadCode.processCmt ~cmtFilePath;
    if runConfig.exception_ then cmt_infos |> Exception.processCmt;
    if runConfig.noalloc then cmt_infos |> Noalloc.processCmt;
    if runConfig.termination then cmt_infos |> Arnold.processCmt
  | _ -> ()

let processCmtFiles ~root =
  let ( +++ ) = Filename.concat in
  let isCmtFile path =
    Filename.check_suffix path ".cmt" || Filename.check_suffix path ".cmti"
  in
  Cli.cmtCommand := true;
  let rec walkSubDirs dir =
    let absDir = match dir = "" with true -> root | false -> root +++ dir in
    let skipDir =
      let base = Filename.basename dir in
      base = "node_modules" || base = "_esy"
    in
    if skipDir || not (Sys.file_exists absDir) then []
    else if Sys.is_directory absDir then
      absDir |> Sys.readdir |> Array.fold_left
        (fun acc d -> acc @ walkSubDirs (dir +++ d))
        []
    else if isCmtFile absDir then [absDir]
    else []
  in
  walkSubDirs "" |> List.iter (loadCmtFile ~cmtRoot:(Some root))

let runAnalysis ~root ~ppf =
  Log_.Color.setup ();
  if !Common.Cli.json then EmitJson.start ();

  processCmtFiles ~root;
  if runConfig.dce then (
    DeadException.forceDelayedItems ();
    DeadOptionalArgs.forceDelayedItems ();
    DeadCommon.reportDead ~checkOptionalArg:DeadOptionalArgs.check ppf;
    DeadCommon.WriteDeadAnnotations.write ());
  if runConfig.exception_ then Exception.reportResults ~ppf;
  if runConfig.noalloc then Noalloc.reportResults ~ppf;
  if runConfig.termination then Arnold.reportResults ~ppf;
  let nIssues = Log_.Stats.report () in
  Log_.Stats.clear ();
  if !Common.Cli.json then EmitJson.finish ();
  if nIssues > 0 && !Common.Cli.exitCode then exit 1

let cli () =
  let analysisKindSet = ref false in
  let cmtRootRef = ref None in
  let usage = "reanalyze version " ^ Version.version in
  let versionAndExit () =
    print_endline usage;
    exit 0
    [@@raises exit]
  in
  let setAll root =
    RunConfig.all ();
    cmtRootRef := Some root;
    analysisKindSet := true
  in
  let setDCE root =
    RunConfig.dce ();
    cmtRootRef := Some root;
    analysisKindSet := true
  in
  let setException root =
    RunConfig.exception_ ();
    cmtRootRef := Some root;
    analysisKindSet := true
  in
  let setNoalloc root =
    RunConfig.noalloc ();
    cmtRootRef := Some root;
    analysisKindSet := true
  in
  let setTermination root =
    RunConfig.termination ();
    cmtRootRef := Some root;
    analysisKindSet := true
  in
  let speclist =
    [
      ( "-all-cmt",
        Arg.String setAll,
        "root_path Run all the analyses for all the .cmt files under the root \
         path" );
      ("-ci", Unit (fun () -> Cli.ci := true), "Internal flag for use in CI");
      ("-debug", Unit (fun () -> Cli.debug := true), "Print debug information");
      ( "-dce-cmt",
        String setDCE,
        "root_path Experimental DCE for all the .cmt files under the root path"
      );
      ( "-exception-cmt",
        String setException,
        "root_path Experimental exception analysis for all the .cmt files \
         under the root path" );
      ( "-native-build-target",
        String (fun s -> Common.Cli.nativeBuildTarget := Some s),
        "A path for the build target, defaults to ''. Can be useful for native \
         projects that use dune to set this to '_build/default'" );
      ( "-exclude-paths",
        String
          (fun s ->
            let paths = s |> String.split_on_char ',' in
            Common.Cli.excludePaths := paths @ Common.Cli.excludePaths.contents),
        "comma-separated-path-prefixes Exclude from analysis files whose path \
         has a prefix in the list" );
      ( "-experimental",
        Set Common.Cli.experimental,
        "Turn on experimental analyses (this option is currently unused)" );
      ( "-externals",
        Set DeadCommon.Config.analyzeExternals,
        "Report on externals in dead code analysis" );
      ("-json", Set Common.Cli.json, "Print reports in json format");
      ( "-live-names",
        String
          (fun s ->
            let names = s |> String.split_on_char ',' in
            Common.Cli.liveNames := names @ Common.Cli.liveNames.contents),
        "comma-separated-names Consider all values with the given names as live"
      );
      ( "-live-paths",
        String
          (fun s ->
            let paths = s |> String.split_on_char ',' in
            Common.Cli.livePaths := paths @ Common.Cli.livePaths.contents),
        "comma-separated-path-prefixes Consider all values whose path has a \
         prefix in the list as live" );
      ("-noalloc-cmt", String setNoalloc, "");
      ( "-set-exit-code",
        Set Common.Cli.exitCode,
        "Exit with code 1 in case an issue is detected" );
      ( "-suppress",
        String
          (fun s ->
            let names = s |> String.split_on_char ',' in
            runConfig.suppress <- names @ runConfig.suppress),
        "comma-separated-path-prefixes Don't report on files whose path has a \
         prefix in the list" );
      ( "-termination-cmt",
        String setTermination,
        "root_path Experimental termination analysis for all the .cmt files \
         under the root path" );
      ( "-unsuppress",
        String
          (fun s ->
            let names = s |> String.split_on_char ',' in
            runConfig.unsuppress <- names @ runConfig.unsuppress),
        "comma-separated-path-prefixes Report on files whose path has a prefix \
         in the list, overriding -suppress (no-op if -suppress is not \
         specified)" );
      ("-version", Unit versionAndExit, "Show version information and exit");
      ("--version", Unit versionAndExit, "Show version information and exit");
      ( "-write",
        Set Common.Cli.write,
        "Write @dead annotations directly in the source files" );
    ]
  in
  let ppf = Format.std_formatter in
  Arg.parse speclist print_endline usage;
  match (!analysisKindSet, !cmtRootRef) with
  | true, Some root -> runAnalysis ~root ~ppf
  | _ ->
    prerr_endline
      "Error: no analysis selected. Pass one of -all-cmt, -dce-cmt, \
       -exception-cmt, -termination-cmt with the root path containing the \
       .cmt files.";
    exit 1
  [@@raises exit]
;;

cli () [@@raises exit]
