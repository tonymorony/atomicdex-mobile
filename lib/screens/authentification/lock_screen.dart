import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komodo_dex/blocs/authenticate_bloc.dart';
import 'package:komodo_dex/blocs/camo_bloc.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/startup_provider.dart';
import 'package:komodo_dex/model/updates_provider.dart';
import 'package:komodo_dex/model/wallet.dart';
import 'package:komodo_dex/model/wallet_security_settings_provider.dart';
import 'package:komodo_dex/screens/authentification/authenticate_page.dart';
import 'package:komodo_dex/screens/authentification/create_password_page.dart';
import 'package:komodo_dex/screens/authentification/pin_page.dart';
import 'package:komodo_dex/screens/authentification/unlock_wallet_page.dart';
import 'package:komodo_dex/screens/settings/updates_page.dart';
import 'package:komodo_dex/services/db/database.dart';
import 'package:komodo_dex/utils/log.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:local_auth/local_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Protective layer: MyApp | LockScreen | MyHomePage.
/// Also handles the application startup.
class LockScreen extends StatefulWidget {
  const LockScreen({
    Key key,
    this.pinStatus = PinStatus.NORMAL_PIN,
    this.child,
    this.onSuccess,
    @required this.context,
  }) : super(key: key);

  final PinStatus pinStatus;
  final Widget child;
  final Function onSuccess;
  final BuildContext context;

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String password;
  bool isInitPassword = false;
  UpdatesProvider updatesProvider;
  bool shouldUpdate = false;

  Future<void> _initScreen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isPinCreationInProgress =
        prefs.containsKey('is_pin_creation_in_progress');
    final Wallet currentWallet = await Db.getCurrentWallet();

    if (password == null && isPinCreationInProgress && currentWallet != null) {
      Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
            builder: (BuildContext context) => UnlockWalletPage(
                  isCreatedPin: true,
                  textButton: AppLocalizations.of(context).login,
                  wallet: currentWallet,
                  onSuccess: (String seed, String password) async {
                    setState(() {
                      this.password = password;
                    });
                    Navigator.of(context).pop();
                  },
                )),
      );
    }
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    Log('lock_screen connectivity: ]', result.toString());
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
        mainBloc.setNetworkStatus(NetworkStatus.Online);
        break;
      case ConnectivityResult.none:
        mainBloc.setNetworkStatus(NetworkStatus.Offline);
        break;
      default:
        mainBloc.setNetworkStatus(NetworkStatus.Offline);
        break;
    }
  }

  Future<void> initConnectivity() async {
    try {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } on PlatformException catch (e) {
      Log('lock_screen connectivity: ]', '$e');
    }
    return _updateConnectionStatus;
  }

  @override
  void initState() {
    super.initState();
    final ScreenArguments args =
        ModalRoute.of(widget.context).settings.arguments;
    password = args?.password;
    _initScreen();

    initConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      pinScreenOrientation(context);

      if (updatesProvider.status == null &&
          mainBloc.networkStatus == NetworkStatus.Online) {
        await updatesProvider.check();
      }
      setState(() {
        shouldUpdate = updatesProvider.status == UpdateStatus.recommended ||
            updatesProvider.status == UpdateStatus.required;
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StartupProvider startup = Provider.of<StartupProvider>(context);
    updatesProvider = Provider.of<UpdatesProvider>(context);
    final walletSecuritySettingsProvider =
        context.read<WalletSecuritySettingsProvider>();

    Widget _buildSplash(String message) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? 'assets/branding/logo_app_light.png'
                    : 'assets/branding/logo_app.png',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            ],
          ),
        ),
      );
    }

    if (!startup.live) {
      final RegExpMatch _tailMatch =
          RegExp(r'([^\n\r]*)$').firstMatch(startup.log);
      final String _logTail = _tailMatch == null ? '' : _tailMatch[0];
      return _buildSplash(_logTail);
    } else if (updatesProvider.status == null &&
        mainBloc.networkStatus == NetworkStatus.Online) {
      return _buildSplash(AppLocalizations.of(context).checkingUpdates);
    }

    return StreamBuilder<bool>(
      stream: authBloc.outIsLogin,
      initialData: authBloc.isLogin,
      builder: (BuildContext context, AsyncSnapshot<bool> isLogin) {
        return StreamBuilder<PinStatus>(
          initialData: authBloc.pinStatus,
          stream: authBloc.outpinStatus,
          builder:
              (BuildContext context, AsyncSnapshot<dynamic> outShowCreatePin) {
            if (outShowCreatePin.hasData &&
                outShowCreatePin.data == PinStatus.NORMAL_PIN) {
              if (isLogin.hasData && isLogin.data) {
                return StreamBuilder<bool>(
                  initialData: authBloc.showLock,
                  stream: authBloc.outShowLock,
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> outShowLock) {
                    if (outShowLock.hasData && outShowLock.data) {
                      if (walletSecuritySettingsProvider
                          .activatePinProtection) {
                        return Stack(
                          children: <Widget>[
                            FutureBuilder<bool>(
                              future: canCheckBiometrics,
                              builder: (BuildContext context,
                                  AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data &&
                                    widget.pinStatus == PinStatus.NORMAL_PIN) {
                                  Log.println('lock_screen:141', snapshot.data);
                                  if (isLogin.hasData && isLogin.data) {
                                    authenticateBiometrics(
                                            context, widget.pinStatus)
                                        .then((_) {
                                      // If last login was camo and camo active value is kept,
                                      // then reset coin balance, this should happen only once
                                      // due to bio and camo between incompatible with each other
                                      if (camoBloc.isCamoActive) {
                                        camoBloc.isCamoActive = false;
                                        coinsBloc.resetCoinBalance();
                                      }
                                    });
                                  }
                                  return SizedBox();
                                }
                                return SizedBox();
                              },
                            ),
                            shouldUpdate
                                ? UpdatesPage(
                                    refresh: false,
                                    onSkip: () {
                                      setState(() {
                                        shouldUpdate = false;
                                      });
                                    },
                                  )
                                : PinPage(
                                    title:
                                        AppLocalizations.of(context).lockScreen,
                                    subTitle: AppLocalizations.of(context)
                                        .enterPinCode,
                                    pinStatus: widget.pinStatus,
                                    isFromChangingPin: false,
                                    onSuccess: widget.onSuccess,
                                  ),
                          ],
                        );
                      } else {
                        return shouldUpdate
                            ? UpdatesPage(
                                refresh: false,
                                onSkip: () {
                                  setState(() {
                                    shouldUpdate = false;
                                  });
                                },
                              )
                            : walletSecuritySettingsProvider
                                    .activateBioProtection
                                ? Stack(
                                    children: <Widget>[
                                      BiometricPage(
                                        pinStatus: widget.pinStatus,
                                      ),
                                    ],
                                  )
                                : widget.child;
                      }
                    } else {
                      if (widget.child == null &&
                          (widget.pinStatus == PinStatus.DISABLED_PIN ||
                              widget.pinStatus ==
                                  PinStatus.DISABLED_PIN_BIOMETRIC))
                        return PinPage(
                          title: AppLocalizations.of(context).lockScreen,
                          subTitle: AppLocalizations.of(context).enterPinCode,
                          pinStatus: widget.pinStatus,
                          isFromChangingPin: false,
                        );
                      else
                        return widget.child;
                    }
                  },
                );
              } else {
                return const AuthenticatePage();
              }
            } else {
              return PinPage(
                title: AppLocalizations.of(context).createPin,
                subTitle: AppLocalizations.of(context).enterPinCode,
                firstCreationPin: true,
                pinStatus: PinStatus.CREATE_PIN,
                password: password,
                isFromChangingPin: false,
              );
            }
          },
        );
      },
    );
  }
}

class BiometricPage extends StatefulWidget {
  const BiometricPage({
    Key key,
    this.pinStatus,
    this.onSuccess,
  }) : super(key: key);

  final PinStatus pinStatus;
  final Function onSuccess;

  @override
  _BiometricPageState createState() => _BiometricPageState();
}

class _BiometricPageState extends State<BiometricPage> {
  IconData iconData = Icons.fingerprint;

  @override
  void initState() {
    canCheckBiometrics.then((bool onValue) async {
      if (onValue && (widget.pinStatus == PinStatus.NORMAL_PIN)) {
        final LocalAuthentication auth = LocalAuthentication();
        final List<BiometricType> availableBiometrics =
            await auth.getAvailableBiometrics();

        if (Platform.isIOS) {
          if (availableBiometrics.contains(BiometricType.face)) {
            setState(() {
              iconData = Icons.visibility;
            });
          }
        }
        authenticateBiometrics(context, widget.pinStatus);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarStatus(
        context: context,
        pinStatus: PinStatus.NORMAL_PIN,
        title: 'Fingerprint',
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              iconData,
              size: 56,
            ),
            const SizedBox(
              height: 16,
            ),
            ElevatedButton(
              onPressed: () =>
                  authenticateBiometrics(context, widget.pinStatus),
              child:
                  Text(AppLocalizations.of(context).authenticate.toUpperCase()),
            )
          ],
        ),
      ),
    );
  }
}
