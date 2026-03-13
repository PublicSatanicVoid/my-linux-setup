;; extends
((call
  function: (identifier) @function.builtin)
  (#any-of? @function.builtin
    "breakpoint" "delattr" "dir" "eval" "exec"
    "getattr" "globals" "hasattr" "locals" "next"
    "setattr" "type" "vars")
  (#set! priority 150))
