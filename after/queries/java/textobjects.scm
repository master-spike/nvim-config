; extends
; Treat records, interfaces and enums as @class so af/if-style class text
; objects (dac/dic/yac/...) work on them, including innermost when nested.

(record_declaration
  body: (class_body) @class.inner) @class.outer

(interface_declaration
  body: (interface_body) @class.inner) @class.outer

(enum_declaration
  body: (enum_body) @class.inner) @class.outer
