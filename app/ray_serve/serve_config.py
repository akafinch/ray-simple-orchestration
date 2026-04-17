"""Ray Serve entrypoint — binds CLIP and CLAP deployments.

Not used directly in the RayService CRD (which references each deployment module
individually via serveConfigV2), but useful for local development:

    serve run serve_config:clip_embed_app
    serve run serve_config:clip_classify_app
    serve run serve_config:clap_embed_app
    serve run serve_config:clap_classify_app
"""

from clip_deployment import embedder_app as clip_embed_app, classifier_app as clip_classify_app
from clap_deployment import embedder_app as clap_embed_app, classifier_app as clap_classify_app
