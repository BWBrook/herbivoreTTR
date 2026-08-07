.value_changing_double <- function(value) {
  structure(
    as.double(value),
    class = "herbivore_ttr_test_value_changing_double"
  )
}

.with_value_changing_double_method <- function(code) {
  class_name <- "herbivore_ttr_test_value_changing_double"
  method_name <- paste("as.double", class_name, sep = ".")
  method_table <- get(".__S3MethodsTable__.", envir = baseenv())
  had_method <- exists(method_name, envir = method_table, inherits = FALSE)
  previous_method <- if (had_method) {
    get(method_name, envir = method_table, inherits = FALSE)
  } else {
    NULL
  }

  registerS3method(
    "as.double",
    class_name,
    function(value, ...) unclass(value) + 1000,
    envir = environment()
  )
  on.exit({
    if (had_method) {
      assign(method_name, previous_method, envir = method_table)
    } else if (exists(method_name, envir = method_table, inherits = FALSE)) {
      rm(list = method_name, envir = method_table)
    }
  })

  force(code)
}
