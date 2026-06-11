; extends
; Treat records, interfaces and enums as @class so af/if-style class text
; objects (dac/dic/yac/...) work on them, including innermost when nested.

(record_declaration
  body: (class_body) @class.inner) @class.outer

(interface_declaration
  body: (interface_body) @class.inner) @class.outer

(enum_declaration
  body: (enum_body) @class.inner) @class.outer

; Plain @function.inner captures. The bundled query only defines
; function.inner via the `#make-range!` directive, which mini.ai's builtin
; resolver ignores (directive-only captures aren't in the static capture
; list), so `yif`/`dif` did nothing. Capturing each body statement as
; @function.inner makes mini.ai span first..last statement (braces excluded)
; via its quantified-capture handling.
(method_declaration
  body: (block
    "{"
    (_)+ @function.inner
    "}"))

(constructor_declaration
  body: (constructor_body
    "{"
    (_)+ @function.inner
    "}"))
