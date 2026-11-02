(* Types of a submodule of an interface are matched with their
   implementation by their full path. *)
module Color : sig
  type setting = Auto | Never | Unused_setting

  type styles = {error : string; unused_style : string}

  val describe : setting -> string
  val error : styles -> string
end
