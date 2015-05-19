# 0.3.2

1. Fixed the regression when navigation stack would become corrupted after dismissing last node.

# 0.3.1

1. Added support for relative nodes. As long as node doesn't point to the same root it is treated as a relative path
1. Updating parameters on nodes upon navigation. Even if navigating to the same URL, with different query.
1. If navigation doesn't require anything to be mounted, no exception is being thrown anymore.