import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

//notice: push allways as page route because otherwise you can't go back
class GetHealthKitPermission extends StatefulWidget {
  GetHealthKitPermission({super.key, required this.health});
  Health health;
  @override
  State<GetHealthKitPermission> createState() => Get_HealthKitPermissionState();

  static List<HealthDataType> get types =>
      (Platform.isAndroid)
          ? dataTypeKeysAndroid
          : (Platform.isIOS)
          ? dataTypeKeysIOS
          : [];

  static List<HealthDataAccess> get permissions =>
      types
          .map(
            (type) =>
                // can only request READ permissions to the following list of types on iOS
                [
                      HealthDataType.GENDER,
                      HealthDataType.BLOOD_TYPE,
                      HealthDataType.BIRTH_DATE,
                      HealthDataType.APPLE_MOVE_TIME,
                      HealthDataType.APPLE_STAND_HOUR,
                      HealthDataType.APPLE_STAND_TIME,
                      HealthDataType.WALKING_HEART_RATE,
                      HealthDataType.ELECTROCARDIOGRAM,
                      HealthDataType.HIGH_HEART_RATE_EVENT,
                      HealthDataType.LOW_HEART_RATE_EVENT,
                      HealthDataType.IRREGULAR_HEART_RATE_EVENT,
                      HealthDataType.EXERCISE_TIME,
                    ].contains(type)
                    ? HealthDataAccess.READ
                    : HealthDataAccess.READ_WRITE,
          )
          .toList();

  static Future<bool?> hasAllPermissions(Health health) {
    //return health.hasPermissions(types, permissions: permissions);
    return health.hasPermissions([HealthDataType.ACTIVE_ENERGY_BURNED]);
  }
}

class Get_HealthKitPermissionState extends State<GetHealthKitPermission> {
  bool healthConnectInstalled = false;
  bool authorized = false;

  Future<void> installHealthConnect() async =>
      await widget.health.installHealthConnect();

  /// Authorize, i.e. get permissions to access relevant health data.
  Future<void> authorize() async {
    await Permission.activityRecognition.request();

    // requesting access to the data types before reading them
    try {
      authorized = await widget.health.requestAuthorization(
        GetHealthKitPermission.types,
        permissions: GetHealthKitPermission.permissions,
      );

      // request access to read historic data
      await widget.health.requestHealthDataHistoryAuthorization();

      // request access in background
      await widget.health.requestHealthDataInBackgroundAuthorization();
    } catch (error) {
      debugPrint("Exception in authorize: $error");
    }
  }

  /// Gets the Health Connect status on Android.
  Future<HealthConnectSdkStatus> getHealthConnectSdkStatus() async {
    assert(Platform.isAndroid, "This is only available on Android");
    HealthConnectSdkStatus status = HealthConnectSdkStatus.sdkUnavailable;
    status =
        await widget.health.getHealthConnectSdkStatus() ??
        HealthConnectSdkStatus.sdkUnavailable;
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //install the SDK if needed
      body: FutureBuilder(
        future: getHealthConnectSdkStatus(),
        builder: (context, snapshot) {
          if (snapshot.hasData == false) {
            return Center(child: CircularProgressIndicator());
          } else {
            //install sdk if needed
            if (snapshot.data != HealthConnectSdkStatus.sdkAvailable) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    installHealthConnect().then((value) {
                      setState(() {
                        //update to check again if the SDK is installed!
                      });
                    });
                  },
                  child: Text("Install Health Connect"),
                ),
              );
            } else {
              //get permission
              return FutureBuilder(
                future: GetHealthKitPermission.hasAllPermissions(widget.health),
                builder: (context, snapshot) {
                  if (snapshot.hasData == false) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    if (snapshot.data == false) {
                      return TextButton(
                        onPressed: () {
                          //get permission
                          authorize().then((value) {
                            setState(() {
                              print("Authorization finished");
                              GetHealthKitPermission.hasAllPermissions(
                                widget.health,
                              ).then(
                                (value) => print("The new value is: $value"),
                              );
                            });
                          });
                        },
                        child: Center(child: Text("Get permission")),
                      );
                    } else {
                      return Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("All permissions are done. Go back!"),
                        ),
                      );
                    }
                  }
                },
              );
            }
          }
        },
      ),
    );
  }
}
