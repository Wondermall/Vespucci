# 0.4.3

1. Replaced logic of notification: `VSPNavigationManagerNotificationSourceNodeKey` points to the old tree, `VSPNavigationManagerNotificationDestinationNodeKey` points to the new tree.

# 0.4.1

1. Added `VSPNavigationManagerWillNavigateNotification`.

# 0.4

1. Removed `VSPNavigationManagerNotificationParametersKey` from notifcations, use `node.parameters` instead.
1. Renamed `addRuleForHostNodeId:childNodeId:mountBlock:unmountBlock:`
1. Making sure `navigationNode` on a `VSPNavigatable` view controller won't be reassigned if it didn't change.
1. Making sure `parameters` on `VSPNavigationNode` won't be reassigned if they didn't change.

# 0.3.2

1. Fixed the regression when navigation stack would become corrupted after dismissing last node.

# 0.3.1

1. Added support for relative nodes. As long as node doesn't point to the same root it is treated as a relative path
1. Updating parameters on nodes upon navigation. Even if navigating to the same URL, with different query.
1. If navigation doesn't require anything to be mounted, no exception is being thrown anymore.