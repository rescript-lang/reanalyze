let () =
  Deadcode.exposed ();
  Modules.LiveNested.value ();
  Modules.use_partly_live ();
  ModuleAliases.use_alias ();
  Includes.use_included ();
  ignore (Types.make_live 1);
  ignore TransitiveTypes.live_value;
  FirstClassModules.run ();
  OptionalArgs.live_optional ~used:1 ();
  ignore (Externals.live_external "abc");
  Annotations.live_value ();
  Exceptions.catches ()
