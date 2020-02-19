rule "namespace_specification" {
  description = "Check namespace name is not empty"

  conditions = [
    "${jsonpath("metadata.namespace") != ""}",
  ]

  report {
    level   = "ERROR"
    message = "Namespace is not specified"
  }
}
