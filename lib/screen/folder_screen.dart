// lib/screen/folder_screen.dart
import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../database/db_helper.dart';
import 'card_screen.dart';

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late Future<List<Folder>> foldersFuture;

  @override
  void initState() {
    super.initState();
    foldersFuture = DBHelper().getFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folders'),
      ),
      body: FutureBuilder<List<Folder>>(
        future: foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final folders = snapshot.data!;
            return ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return FolderListItem(folder: folder);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading folders'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class FolderListItem extends StatelessWidget {
  final Folder folder;

  FolderListItem({required this.folder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: DBHelper().getCardCountInFolder(folder.id!),
      builder: (context, snapshot) {
        int cardCount = snapshot.data ?? 0;
        return ListTile(
          title: Text(folder.name),
          subtitle: Text('$cardCount cards'),
          trailing: cardCount < 3
              ? Icon(Icons.warning, color: Colors.red)
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardScreen(folder: folder),
              ),
            );
          },
        );
      },
    );
  }
}
