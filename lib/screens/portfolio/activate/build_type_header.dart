import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/localizations.dart';

class BuildTypeHeader extends StatefulWidget {
  const BuildTypeHeader({Key key, this.type}) : super(key: key);

  // `null` for 'test coins' category
  final String type;

  @override
  _BuildTypeHeaderState createState() => _BuildTypeHeaderState();
}

class _BuildTypeHeaderState extends State<BuildTypeHeader> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoinToActivate>>(
        initialData: coinsBloc.coinBeforeActivation,
        stream: coinsBloc.outCoinBeforeActivation,
        builder: (context, snapshot) {
          final bool isActive = _areAllActive(snapshot.data);

          // todo(MRC): Optimize this to use CheckboxListTile in a future point in time
          return InkWell(
            onTap: () => coinsBloc.setCoinsBeforeActivationByType(
                widget.type, !isActive),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              child: Row(
                children: <Widget>[
                  Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? Theme.of(context).toggleableActiveColor
                              : Colors.transparent,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                          ))),
                  const SizedBox(width: 24),
                  Flexible(
                    child: Text(
                      _getTitleText(),
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  String _getTitleText() {
    switch (widget.type) {
      case 'erc':
        return AppLocalizations.of(context).searchFilterSubtitleERC;
        break;
      case 'bep':
        return AppLocalizations.of(context).searchFilterSubtitleBEP;
        break;
      case 'plg':
        return AppLocalizations.of(context).searchFilterSubtitlePLG;
        break;
      case 'qrc':
        return AppLocalizations.of(context).searchFilterSubtitleQRC;
        break;
      case 'utxo':
        return AppLocalizations.of(context).searchFilterSubtitleutxo;
        break;
      case 'smartChain':
        return AppLocalizations.of(context).searchFilterSubtitleSmartChain;
        break;
      default:
        return AppLocalizations.of(context).searchFilterSubtitleTestCoins;
    }
  }

  bool _areAllActive(List<CoinToActivate> coinsBeforeActivation) {
    bool areAllActive = true;

    for (CoinToActivate item in coinsBeforeActivation) {
      if (item.isActive) continue;

      // `widget.type == null` for test coins
      if (widget.type == null) {
        if (item.coin.testCoin) areAllActive = false;
      } else {
        if (item.coin.type == widget.type && !item.coin.testCoin)
          areAllActive = false;
      }
    }

    return areAllActive;
  }
}