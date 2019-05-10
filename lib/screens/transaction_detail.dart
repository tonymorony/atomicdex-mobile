import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/transactions.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionDetail extends StatefulWidget {
  final Transaction transaction;
  final CoinBalance coinBalance;

  TransactionDetail({this.transaction, this.coinBalance});

  @override
  _TransactionDetailState createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              String fromOrTo = widget.transaction.myBalanceChange > 0
                  ? 'From: ${widget.transaction.from[0]}'
                  : 'To ${widget.transaction.to.length > 1 ? widget.transaction.to[1] : widget.transaction.to[0]}';

              String dataToShare =
                  'Transaction detail:\nAmount: ${widget.transaction.myBalanceChange} ${widget.transaction.coin}\nDate: ${widget.transaction.getTimeFormat()}\nBlock: ${widget.transaction.blockHeight}\nConfirmations: ${widget.transaction.confirmations}\nFee: ${widget.transaction.feeDetails.amount} ${widget.transaction.coin}\n${fromOrTo}\nTx Hash: ${widget.transaction.txHash}';

              Share.share(dataToShare);
            },
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: (){
              _launchURL(widget.coinBalance.coin.explorerUrl[0] + "tx/" + widget.transaction.txHash);
            },
          )
        ],
        elevation: 0,
      ),
      body: ListView(
        children: <Widget>[_buildHeader(), _buildListDetails()],
      ),
    );
  }

  _launchURL(String url) async {
    print(url);
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

  _buildHeader() {
    Transaction tx = widget.transaction;
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: AutoSizeText(
                        tx.myBalanceChange.toString() + " " + tx.coin,
                        style: Theme.of(context).textTheme.title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Text(
                    (widget.coinBalance.priceForOne * tx.myBalanceChange)
                            .toStringAsFixed(2) +
                        " USD",
                    style: Theme.of(context).textTheme.body2,
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  tx.getTimeFormat(),
                  style: Theme.of(context).textTheme.body2,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: tx.confirmations > 0
                        ? Colors.lightGreen
                        : Colors.red.shade500,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: tx.confirmations > 0
                      ? Text("CONFIRMED")
                      : Text("NOT CONFIRMED"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  _buildListDetails() {
    return Column(
      children: <Widget>[
        widget.transaction.blockHeight > 0 ? ItemTransationDetail(
            title: "Block", data: widget.transaction.blockHeight.toString()) : Container(),
        ItemTransationDetail(
            title: "Confirmations",
            data: widget.transaction.confirmations.toString()),
        ItemTransationDetail(
            title: "Fee",
            data: widget.transaction.feeDetails.amount.toString() +
                " " +
                widget.transaction.coin),
        widget.transaction.myBalanceChange > 0
            ? ItemTransationDetail(
                title: "From", data: widget.transaction.from[0])
            : ItemTransationDetail(title: "To", data: widget.transaction.to.length > 1 ? widget.transaction.to[1] : widget.transaction.to[0]),
        ItemTransationDetail(title: "Tx Hash", data: widget.transaction.txHash),
      ],
    );
  }
}

class ItemTransationDetail extends StatelessWidget {
  final String title;
  final String data;

  ItemTransationDetail({this.title, this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        copyToClipBoard(context, data);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.subtitle,
            ),
            SizedBox(
              width: 16,
            ),
            Expanded(
              child: AutoSizeText(
                data,
                style: Theme.of(context).textTheme.body2,
                textAlign: TextAlign.end,
              ),
            )
          ],
        ),
      ),
    );
  }
}