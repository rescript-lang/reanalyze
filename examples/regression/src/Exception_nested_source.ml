module Inner = struct
  exception Direct = Not_found
  exception Through_chain = Not_found
  exception Through_nested_alias = Not_found
  exception Through_include = Not_found
  exception Unused = Not_found

  module Deep = struct
    exception Used = Not_found
    exception Unused = Not_found
  end
end
