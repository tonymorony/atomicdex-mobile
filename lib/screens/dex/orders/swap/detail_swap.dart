import 'package:flutter/material.dart';
import 'package:komodo_dex/app_config/theme_data.dart';
import 'package:komodo_dex/blocs/camo_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/swap.dart';
import 'package:komodo_dex/screens/dex/orders/swap/detailed_swap_steps.dart';
import 'package:komodo_dex/services/db/database.dart';
import 'package:komodo_dex/utils/utils.dart';

class DetailSwap extends StatefulWidget {
  const DetailSwap({@required this.swap});

  final Swap swap;

  @override
  _DetailSwapState createState() => _DetailSwapState();
}

class _DetailSwapState extends State<DetailSwap> {
  String noteText;
  bool isNoteEdit = false;
  bool isNoteExpanded = false;
  final noteTextController = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Db.getNote(widget.swap.result.uuid).then((n) {
      setState(() {
        noteText = n;
        noteTextController.text = noteText;
      });
    });
  }

  @override
  void dispose() {
    noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          color: const Color.fromARGB(255, 52, 62, 76),
          height: 1,
          width: double.infinity,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32, left: 24, right: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).tradeDetail + ':',
                  style: Theme.of(context).textTheme.subtitle2.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold),
                ),
              ),
              _buildMakerTakerBadge(widget.swap.result.type == 'Maker'),
            ],
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 4),
          child: Text(
            AppLocalizations.of(context).requestedTrade + ':',
            style: Theme.of(context)
                .textTheme
                .bodyText1
                .copyWith(fontWeight: FontWeight.w400),
          ),
        ),
        _buildAmountSwap(),
        _buildNote(AppLocalizations.of(context).noteTitle),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _buildInfo(
            AppLocalizations.of(context).swapUUID,
            widget.swap.result.uuid,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        DetailedSwapSteps(uuid: widget.swap.result.uuid),
        const SizedBox(
          height: 32,
        ),
      ],
    );
  }

  Widget _buildMakerTakerBadge(bool isMaker) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Theme.of(context).textTheme.caption.color.withAlpha(100),
          style: BorderStyle.solid,
          width: 1,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Text(
          isMaker
              ? AppLocalizations.of(context).makerOrder
              : AppLocalizations.of(context).takerOrder,
          style: Theme.of(context).textTheme.caption,
        ),
      ),
    );
  }

  Widget _buildNote(String title) {
    return Row(
      crossAxisAlignment:
          isNoteEdit ? CrossAxisAlignment.center : CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: InkWell(
            onTap: isNoteEdit
                ? null
                : () {
                    setState(() {
                      isNoteEdit = true;
                    });

                    noteTextController.text = noteTextController.text.trim();
                    noteText = noteTextController.text;
                    focusNode.requestFocus();

                    if (noteText != null && noteText.isNotEmpty) {
                      setState(() {
                        isNoteExpanded = !isNoteExpanded;
                      });
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 0, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      title + ':',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                  ),
                  isNoteEdit
                      ? Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: gefaultUnderlineInputTheme,
                          ),
                          child: TextField(
                            decoration: InputDecoration(isDense: true),
                            controller: noteTextController,
                            maxLength: 200,
                            maxLines: 7,
                            minLines: 1,
                            focusNode: focusNode,
                          ),
                        )
                      : Text(
                          (noteText == null || noteText.isEmpty)
                              ? AppLocalizations.of(context).notePlaceholder
                              : noteText,
                          style: Theme.of(context).textTheme.bodyText2.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: isNoteExpanded ? null : 1,
                          overflow:
                              isNoteExpanded ? null : TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(isNoteEdit ? Icons.check : Icons.edit),
          onPressed: () {
            setState(
              () {
                if (isNoteEdit) {
                  noteTextController.text = noteTextController.text.trim();
                  noteText = noteTextController.text;

                  noteText.isNotEmpty
                      ? Db.saveNote(widget.swap.result.uuid, noteText)
                      : Db.deleteNote(widget.swap.result.uuid);

                  setState(() {
                    isNoteExpanded = false;
                  });
                } else {
                  focusNode.requestFocus();
                }

                setState(() {
                  isNoteEdit = !isNoteEdit;
                });
              },
            );
          },
        ),
        if (noteText?.isNotEmpty ?? false)
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              copyToClipBoard(context, noteText);
            },
          ),
      ],
    );
  }

  Widget _buildInfo(
    String title,
    String id,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title + ':',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          InkWell(
            onTap: () => copyToClipBoard(context, id),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child:
                        Text(id, style: Theme.of(context).textTheme.bodyText2),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAmountSwap() {
    final myInfo = extractMyInfoFromSwap(widget.swap.result);
    final myCoin = myInfo['myCoin'];
    final myAmount = myInfo['myAmount'];
    final otherCoin = myInfo['otherCoin'];
    final otherAmount = myInfo['otherAmount'];

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(flex: 1),
            1: IntrinsicColumnWidth(),
            2: IntrinsicColumnWidth(flex: 1),
          },
          children: [
            TableRow(
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: _buildTextAmount(myCoin, myAmount),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Row(
                    children: [
                      _buildIcon(myCoin),
                      Icon(Icons.sync, size: 20),
                      _buildIcon(otherCoin),
                    ],
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: _buildTextAmount(otherCoin, otherAmount,
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            TableRow(
              children: [
                Text(
                  AppLocalizations.of(context).sell.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontWeight: FontWeight.w400),
                ),
                SizedBox(),
                Text(
                  AppLocalizations.of(context).receive.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontWeight: FontWeight.w400),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildTextAmount(String coin, String amount,
      {TextAlign textAlign = TextAlign.left}) {
    // Only apply camouflage to swap history,
    // show current active swaps as is
    final bool shouldCamouflage = camoBloc.isCamoActive &&
        (widget.swap.status == Status.SWAP_SUCCESSFUL ||
            widget.swap.status == Status.SWAP_FAILED ||
            widget.swap.status == Status.TIME_OUT);

    if (shouldCamouflage) {
      amount = (double.parse(amount) * camoBloc.camoFraction / 100).toString();
    }

    return Text(
      (double.parse(amount) % 1) == 0
          ? double.parse(amount).toString() + ' ' + coin
          : double.parse(amount).toStringAsFixed(4) + ' ' + coin,
      style: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
      textAlign: textAlign,
    );
  }

  Widget _buildIcon(String coin) {
    return SizedBox(
      height: 25,
      width: 25,
      child: Image.asset(
        'assets/coin-icons/${coin.toLowerCase()}.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
