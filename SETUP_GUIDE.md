# Quick Setup Guide - Drup App

### Step 2: Get Google Maps API Key

1. Go to: https://console.cloud.google.com/
2. Create a new project
3. Enable these APIs:
   - Maps SDK for Android: 
   - Maps SDK for iOS: 
   - Directions API
   - Places API
   - Geocoding API
4. Create API Key

 final _scaffoldKey = GlobalKey<ScaffoldState>();
 _scaffoldKey.currentState?.showBottomSheet(
              enableDrag: true,
              showDragHandle: true,
              (context) => NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    _bottomSheetHeight =
                        notification.extent * MediaQuery.of(context).size.height;
                  });
                  return true;
                },
                child: RideSearchBottomSheet(
                  onClose: () {
                    setState(() {
                      _bottomSheetHeight = 0.0;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            );