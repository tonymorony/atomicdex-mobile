import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/main_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/screens/dex/trade/multi/multi_order_page.dart';
import 'package:komodo_dex/screens/dex/trade/pro/create/trade_page.dart';
import 'package:komodo_dex/screens/dex/trade/simple/trade_page_simple.dart';
import 'package:komodo_dex/screens/dex/trade/trade_mode_indicator.dart';

class TradeModesPage extends StatefulWidget {
  @override
  _TradeModesPageState createState() => _TradeModesPageState();
}

class _TradeModesPageState extends State<TradeModesPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  TabController _tradeTabController;

  @override
  void initState() {
    _tradeTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: mainBloc.tradeMode,
    );
    _tradeTabController.addListener(() {
      mainBloc.tradeMode = _tradeTabController.index;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildSwitcher(),
        Expanded(child: _buildView()),
      ],
    );
  }

  Widget _buildSwitcher() {
    final style = Theme.of(context)
        .textTheme
        .caption
        .copyWith(color: Theme.of(context).colorScheme.onPrimary);

    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
                child: Text(
              'Trading Mode:',
              style: style,
            )),
            Flexible(
              flex: 2,
              child: TabBar(
                controller: _tradeTabController,
                indicator: TradeModeIndicator(context: context),
                labelPadding: EdgeInsets.symmetric(horizontal: 0),
                indicatorPadding: EdgeInsets.symmetric(horizontal: 0),
                tabs: [
                  Tab(child: Text('Simple', style: style)),
                  Tab(child: Text('Advanced', style: style)),
                  Tab(
                      child: Text(AppLocalizations.of(context).multiTab,
                          style: style)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildView() {
    final List<Widget> views = [
      TradePageSimple(),
      TradePage(),
      MultiOrderPage(),
    ];
    return StreamBuilder<int>(
      initialData: mainBloc.tradeMode,
      stream: mainBloc.outTradeMode,
      builder: (context, snapshot) {
        return views[snapshot.data];
      },
    );
  }
}