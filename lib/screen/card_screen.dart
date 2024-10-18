// lib/screen/card_screen.dart
import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/card_model.dart';
import '../database/db_helper.dart';

class CardScreen extends StatefulWidget {
  final Folder folder;

  CardScreen({required this.folder});

  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late Future<List<CardModel>> cardsFuture;

  @override
  void initState() {
    super.initState();
    cardsFuture = DBHelper().getCards(folderId: widget.folder.id);
  }

  void _refreshCards() {
    setState(() {
      cardsFuture = DBHelper().getCards(folderId: widget.folder.id);
    });
  }

  void _addCard() async {
    int cardCount = await DBHelper().getCardCountInFolder(widget.folder.id!);
    if (cardCount >= 6) {
      _showErrorDialog('This folder can only hold 6 cards.');
      return;
    }

    List<CardModel> unassignedCards =
    await DBHelper().getCards(folderId: null);

    if (unassignedCards.isEmpty) {
      _showErrorDialog('No more cards available to add.');
      return;
    }

    CardModel? selectedCard = await showDialog<CardModel>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Select a card to add'),
          children: unassignedCards.map((card) {
            return SimpleDialogOption(
              child: Text(card.name),
              onPressed: () {
                Navigator.pop(context, card);
              },
            );
          }).toList(),
        );
      },
    );

    if (selectedCard != null) {
      selectedCard.folderId = widget.folder.id;
      await DBHelper().updateCard(selectedCard);
      _refreshCards();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Limit Reached'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCard(CardModel card) async {
    card.folderId = null;
    await DBHelper().updateCard(card);
    _refreshCards();
  }

  void _updateCard(CardModel card) async {
    // For simplicity, we'll allow the user to change the folder assignment
    List<Folder> folders = await DBHelper().getFolders();
    Folder? selectedFolder = await showDialog<Folder>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Select a new folder'),
          children: folders.map((folder) {
            return SimpleDialogOption(
              child: Text(folder.name),
              onPressed: () {
                Navigator.pop(context, folder);
              },
            );
          }).toList(),
        );
      },
    );

    if (selectedFolder != null) {
      int cardCount =
      await DBHelper().getCardCountInFolder(selectedFolder.id!);
      if (cardCount >= 6) {
        _showErrorDialog('Selected folder can only hold 6 cards.');
        return;
      }
      card.folderId = selectedFolder.id;
      await DBHelper().updateCard(card);
      _refreshCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.folder.name),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addCard,
            ),
          ],
        ),
        body: FutureBuilder<List<CardModel>>(
          future: cardsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final cards = snapshot.data!;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return GestureDetector(
                    onTap: () {
                      _showCardOptions(card);
                    },
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              card.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(card.name),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading cards'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ));
  }

  void _showCardOptions(CardModel card) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Remove from folder'),
            onTap: () {
              Navigator.pop(context);
              _deleteCard(card);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Move to another folder'),
            onTap: () {
              Navigator.pop(context);
              _updateCard(card);
            },
          ),
        ],
      ),
    );
  }
}
