; extends
; Add function.inner for function_definition (C++ doesn't define it by default)
; Captures the function body statements, allowing dif/yif/etc to work

(function_definition
  body: (compound_statement
    "{"
    (_)+ @function.inner
    "}"))
