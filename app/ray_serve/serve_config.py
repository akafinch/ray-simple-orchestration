"""Ray Serve entrypoint — binds CLIP and CLAP deployments.

Not used directly in the RayService CRD (which references each deployment module
individually via serveConfigV2), but useful for local development:

    serve run serve_config:clip_app
    serve run serve_config:clap_app
"""

from clip_deployment import CLIPEmbedder
from clap_deployment import CLAPEmbedder

clip_app = CLIPEmbedder.bind()
clap_app = CLAPEmbedder.bind()
