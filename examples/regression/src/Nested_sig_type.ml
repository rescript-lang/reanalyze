module Color = struct
  type setting = Auto | Never | Unused_setting

  type styles = {error : string; unused_style : string}

  let describe = function
    | Auto -> "auto"
    | Never -> "never"
    | Unused_setting -> "unused"

  let error styles = styles.error
end
