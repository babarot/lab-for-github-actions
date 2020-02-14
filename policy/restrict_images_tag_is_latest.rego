package main

# Check name: No latest tag
# Description: Its Docker image tag is not latest or master.

warn_images_tag_is_latest[msg] {
  name := input.metadata.name
  container := input.spec.template.spec.containers[_]
  docker_image := container.image
  restrict_test_images_tag_is_latest(split(docker_image, ":"))
  msg = sprintf("Don't use latest container image tags in Deployment %s", [name])
}

restrict_test_images_tag_is_latest(images) {
  input.kind = "Deployment"
  count(images) < 2
}

restrict_test_images_tag_is_latest([_, tag]) {
  input.kind = "Deployment"
  tag == "latest"
}
