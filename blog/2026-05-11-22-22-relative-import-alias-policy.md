# Relative Import Alias Policy

Relative host imports now have an explicit alias policy in docs and fixtures.

The host import layer still joins the importing file's directory with the
relative path text. It does not canonicalize paths for recursion detection.
That means `./nested/../file.nix` can read successfully because the host
filesystem resolves `..`, but alias-based recursive imports are not yet a
normalized semantic guarantee.

The new import fixture covers the successful simple alias read. The eval
manifest still passes, keeping pure path values as inert parsed text.

