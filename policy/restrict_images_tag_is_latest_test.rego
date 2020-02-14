package main

test_restrict_image_tag_is_latest {
    warn_images_tag_is_latest["Don't use latest container image tags in Deployment sample"] with input as {"kind": "Deployment", "metadata": {"name": "sample"}, "spec": {
        "template": {"spec": {"containers": [ {
            "name": "sample", "image": "gcr.io/echo-jp-prod/echo-jp:latest"
        } ] } } } }
}

test_restrict_no_image_tag {
    warn_images_tag_is_latest["Don't use latest container image tags in Deployment sample"] with input as {"kind": "Deployment", "metadata": {"name": "sample"}, "spec": {
        "template": {"spec": {"containers": [ {
            "name": "sample", "image": "gcr.io/echo-jp-prod/echo-jp"
        } ] } } } }
}

test_allow_image_tag_with_version {
    not warn_images_tag_is_latest["Don't use latest container image tags in Deployment sample"] with input as {"kind": "Deployment", "metadata": {"name": "sample"}, "spec": {
        "template": {"spec": {"containers": [ {
            "name": "sample", "image": "gcr.io/echo-jp-prod/echo-jp:0.0.1"
        } ] } } } }
}
